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
  func didEnterRegion(_ region: CLBeaconRegion)
  func didExitRegion(_ region: CLBeaconRegion)
  func didRangeBeacon(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion)
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
  func startMonitoring(_ beaconRegion: CLBeaconRegion?) {
    Globals.log("Start Monitoring: \((beaconRegion?.proximityUUID.uuidString)!)")
    pendingMonitorRequest = true
    self.beaconRegion = beaconRegion
    //beaconRegions.append(beaconRegion)
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      Globals.log("authorizationStatus: .NotDetermined")
      locationManager.requestAlwaysAuthorization()
    case .restricted, .denied, .authorizedWhenInUse:
      Globals.log("authorizationStatus: .Restricted, .Denied, .AuthorizedWhenInUse")
      delegate?.onBackgroundLocationAccessDisabled()
    case .authorizedAlways:
      Globals.log("authorizationStatus: .AuthorizedAlways")
      locationManager!.startMonitoring(for: beaconRegion!)
      pendingMonitorRequest = false
    }
  }
  
  func stopMonitoringBeacon(_ beaconRegion: CLBeaconRegion?, key: String) {
    Globals.log("Stop Monitoring: \((beaconRegion?.proximityUUID.uuidString)!)")
    locationManager.stopRangingBeacons(in: beaconRegion!)
    locationManager.stopMonitoring(for: beaconRegion!)
    locationManager.stopUpdatingLocation()
    
    if(key != "") {
      if let removedValue = beaconRegions.removeValue(forKey: key) {
        Globals.log("Removed Dictionary: \(removedValue)")
      }
    }
  }
  
  // MARK: CLLocationManagerDelegate Method
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    Globals.log("didChangeAuthorizationStatus: \(status)")
    if (status == .authorizedWhenInUse || status == .authorizedAlways) && beaconRegion != nil {
      if pendingMonitorRequest {
        locationManager!.startMonitoring(for: beaconRegion!)
        pendingMonitorRequest = false
      }
      locationManager!.startUpdatingLocation()
    }
    
    // Make it Nil to save memory
    beaconRegion = nil
  }
  
  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    Globals.log("didStartMonitoringForRegion: \(region.identifier)")
    delegate?.didStartMonitoring()
    locationManager.requestState(for: region)
  }
  
  func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
    Globals.log("monitoringDidFailForRegion: \(error)")
  }
  
  func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
    
    switch state {
    case CLRegionState.inside:
      Globals.log(" - entered region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      locationManager.startRangingBeacons(in: beaconRegion)
      delegate?.didEnterRegion(beaconRegion)
      
    case CLRegionState.outside:
      Globals.log(" - exited region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      locationManager.stopRangingBeacons(in: beaconRegion)
      delegate?.didExitRegion(beaconRegion)
      
    default:
      Globals.log(" - unknown region \(region.identifier)")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    Globals.log("didEnterRegion")
    // TODO: I don't know if I will be needing this in the Future for now I'll just comment it - Francis 08/02/2016
    // didDetermineState's Callback is asynchronous call, and it seems to be doing a good job tracking the RegionState
    /*let beaconRegion = region as! CLBeaconRegion
    delegate?.didEnterRegion(beaconRegion)*/
  }
  
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    Globals.log("didExitRegion")
    // TODO: I don't know if I will be needing this in the Future for now I'll just comment it - Francis 08/02/2016
    // didDetermineState's Callback is asynchronous call, and it seems to be doing a good job tracking the RegionState
    /*let beaconRegion = region as! CLBeaconRegion
    delegate?.didExitRegion(beaconRegion)*/
  }
  
  func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
    NSLog("BEACON: \(beacons)", "")
    //NSLog("REGION: \(region)", "")
    
    let key = region.proximityUUID.uuidString
    
    if beacons.count > 0 {
      var rangedBeacon: CLBeacon! = CLBeacon()
      rangedBeacon = beacons[0]
      let battery: Int = Int(rangedBeacon.minor)
      let absRssiValue = abs(rangedBeacon.rssi)
      var proximityCode: Int = 0
      var rangeImage: String = ""
      
      switch rangedBeacon.proximity {
      case CLProximity.unknown:
        proximityCode = 1
        rangeImage = "range_far"
      case CLProximity.immediate:
        proximityCode = 2
        rangeImage = "range_close"
      case CLProximity.near:
        proximityCode = 3
        rangeImage = "range_intermediary"
      case CLProximity.far:
        proximityCode = 4
        rangeImage = "range_far"
      }
      
      if beaconRegions[key] != nil {
        let oldBattery = beaconRegions[key]![Constants.Key.Battery]
        
        beaconRegions[key]![Constants.Key.Proximity] = proximityCode
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetImageRange), object: nil, userInfo: ["key": key, "rangeImage": rangeImage])
        
        if (oldBattery != battery) {
          beaconRegions[key]![Constants.Key.Battery] = battery
          NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetBattery), object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
        }
      } else {
        beaconRegions[key] = [Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetImageRange), object: nil, userInfo: ["key": key, "rangeImage": rangeImage])
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetBattery), object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, rangingBeaconsDidFailFor region: CLBeaconRegion, withError error: Error) {
    Globals.log("rangingBeaconsDidFailForRegion: \(error)")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    Globals.log("didFailWithError: \(error)")
  }
}
