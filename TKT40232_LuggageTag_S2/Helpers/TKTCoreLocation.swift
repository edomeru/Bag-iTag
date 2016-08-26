//
//  TKTCoreLocation.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import CoreLocation

protocol TKTCoreLocationDelegate: NSObjectProtocol {
  func onBackgroundLocationAccessDisabled()
  func didStartMonitoring()
  func didStopMonitoring()
  func monitoringDidFail()
  func didEnterRegion(region: CLBeaconRegion)
  func didExitRegion(region: CLBeaconRegion)
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion)
  //func onError(error: NSError)
}


class TKTCoreLocation: NSObject, CLLocationManagerDelegate {
  
  var locationManager: CLLocationManager!
  var beaconRegion: CLBeaconRegion?
  var beaconRegions: [String: [String: Int]]
  //var rangedBeacon: CLBeacon! = CLBeacon()
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  init(delegate: TKTCoreLocationDelegate) {
    self.beaconRegions = [String: [String: Int]]()
    super.init()
    self.delegate = delegate
    self.locationManager = CLLocationManager()
    self.locationManager!.delegate = self
  }
  
  // MARK: Action Method
  func startMonitoring(beaconRegion: CLBeaconRegion?) {
    Globals.log("Start Monitoring: \((beaconRegion?.proximityUUID.UUIDString)!)")
    pendingMonitorRequest = true
    self.beaconRegion = beaconRegion
    //beaconRegions.append(beaconRegion)
    
    switch CLLocationManager.authorizationStatus() {
    case .NotDetermined:
      Globals.log("authorizationStatus: .NotDetermined")
      locationManager.requestAlwaysAuthorization()
    case .Restricted, .Denied, .AuthorizedWhenInUse:
      Globals.log("authorizationStatus: .Restricted, .Denied, .AuthorizedWhenInUse")
      delegate?.onBackgroundLocationAccessDisabled()
    case .AuthorizedAlways:
      Globals.log("authorizationStatus: .AuthorizedAlways")
      locationManager!.startMonitoringForRegion(beaconRegion!)
      pendingMonitorRequest = false
    }
  }
  
  func stopMonitoringBeacon(beaconRegion: CLBeaconRegion?, key: String) {
    Globals.log("Stop Monitoring: \((beaconRegion?.proximityUUID.UUIDString)!)")
    locationManager.stopRangingBeaconsInRegion(beaconRegion!)
    locationManager.stopMonitoringForRegion(beaconRegion!)
    locationManager.stopUpdatingLocation()
    
    if(key != "") {
      if let removedValue = beaconRegions.removeValueForKey(key) {
        Globals.log("Removed Dictionary: \(removedValue)")
      }
    }
  }
  
  // MARK: CLLocationManagerDelegate Method
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    Globals.log("didChangeAuthorizationStatus: \(status)")
    if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) && beaconRegion != nil {
      if pendingMonitorRequest {
        locationManager!.startMonitoringForRegion(beaconRegion!)
        pendingMonitorRequest = false
      }
      locationManager!.startUpdatingLocation()
    }
    
    // Make it Nil to save memory
    beaconRegion = nil
  }
  
  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    Globals.log("didStartMonitoringForRegion: \(region.identifier)")
    delegate?.didStartMonitoring()
    locationManager.requestStateForRegion(region)
  }
  
  func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    Globals.log("monitoringDidFailForRegion: \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
    
    switch state {
    case CLRegionState.Inside:
      Globals.log(" - entered region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      
      locationManager.startRangingBeaconsInRegion(beaconRegion)
      delegate?.didEnterRegion(beaconRegion)
      
      if (beaconRegions[beaconRegion.proximityUUID.UUIDString] != nil) {
        if (beaconRegions[beaconRegion.proximityUUID.UUIDString]![Constants.Key.Exited] == 1) {
          beaconRegions.updateValue([Constants.Key.Battery: 0, Constants.Key.rssi: 0, Constants.Key.Proximity: 1, Constants.Key.Exited: 0, Constants.Key.Initialize: 0], forKey: beaconRegion.proximityUUID.UUIDString)
        }
      }
      
    case CLRegionState.Outside:
      Globals.log(" - exited region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      locationManager.stopRangingBeaconsInRegion(beaconRegion)
      delegate?.didExitRegion(beaconRegion)
      
    default:
      Globals.log(" - unknown region \(region.identifier)")
    }
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    Globals.log("didEnterRegion")
    // TODO: I don't know if I will be needing this in the Future for now I'll just comment it - Francis 08/02/2016
    // didDetermineState's Callback is asynchronous call, and it seems to be doing a good job tracking the RegionState
    /*let beaconRegion = region as! CLBeaconRegion
    delegate?.didEnterRegion(beaconRegion)*/
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    Globals.log("didExitRegion")
    // TODO: I don't know if I will be needing this in the Future for now I'll just comment it - Francis 08/02/2016
    // didDetermineState's Callback is asynchronous call, and it seems to be doing a good job tracking the RegionState
    /*let beaconRegion = region as! CLBeaconRegion
    delegate?.didExitRegion(beaconRegion)*/
  }
  
  func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
    //NSLog("BEACON: \(beacons)", "")
    //NSLog("REGION: \(region)", "")
    
    let key = region.proximityUUID.UUIDString
    
    if beacons.count > 0 {
      var rangedBeacon: CLBeacon! = CLBeacon()
      let battery: Int = Int(rangedBeacon.minor)
      rangedBeacon = beacons[0]
      let absRssiValue = abs(rangedBeacon.rssi)
      var proximityCode: Int = 0
      
      switch rangedBeacon.proximity {
      case CLProximity.Unknown:
        proximityCode = 1
      case CLProximity.Immediate:
        proximityCode = 2
      case CLProximity.Near:
        proximityCode = 3
      case CLProximity.Far:
        proximityCode = 4
      }
      
      if beaconRegions[key] != nil {
        if (absRssiValue != beaconRegions[key]![Constants.Key.rssi]) {
          let oldRssiValue = beaconRegions[key]![Constants.Key.rssi]
          
          if (absRssiValue == 0 && oldRssiValue > 0) {
            beaconRegions.updateValue([Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode, Constants.Key.Exited: 1, Constants.Key.Initialize: 0], forKey: key)
            delegate?.didExitRegion(region)
          }
          
          if (absRssiValue > 0 && oldRssiValue == 0) {
            beaconRegions.updateValue([Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode, Constants.Key.Exited: 0, Constants.Key.Initialize: 0], forKey: key)
            delegate?.didEnterRegion(region)
          }
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.SetBattery, object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
      } else {
        
        if (absRssiValue == 0) {
          beaconRegions[key] = [Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode, Constants.Key.Exited: 1, Constants.Key.Initialize: 0]
          delegate?.didExitRegion(region)
        } else {
          beaconRegions[key] = [Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode, Constants.Key.Exited: 0, Constants.Key.Initialize: 0]
          delegate?.didEnterRegion(region)
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.SetBattery, object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
      }
    } else {
      
      if (beaconRegions[key] == nil) {
        
        beaconRegions[key] = [Constants.Key.Battery: 0, Constants.Key.rssi: 0, Constants.Key.Proximity: 1, Constants.Key.Exited: 1, Constants.Key.Initialize: 1]
        delegate?.didExitRegion(region)
        
      } else if (beaconRegions[key]![Constants.Key.Exited] == 0) {
        
        beaconRegions.updateValue([Constants.Key.Battery: 0, Constants.Key.rssi: 0, Constants.Key.Proximity: 1, Constants.Key.Exited: 1, Constants.Key.Initialize: 0], forKey: key)
        delegate?.didExitRegion(region)
        
      } else if (beaconRegions[key]![Constants.Key.Battery] == 0 && beaconRegions[key]![Constants.Key.rssi] == 0 &&
          beaconRegions[key]![Constants.Key.Proximity] == 1 && beaconRegions[key]![Constants.Key.Exited] == 1 && beaconRegions[key]!["intialize"] == 0) {
        delegate?.didExitRegion(region)
      }
      
    }
  }
  
  func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    Globals.log("rangingBeaconsDidFailForRegion: \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    Globals.log("didFailWithError: \(error)")
  }
}
