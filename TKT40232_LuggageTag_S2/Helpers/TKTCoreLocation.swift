//
//  TKTCoreLocation.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit
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
  var appState: UIApplicationState
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  init(delegate: TKTCoreLocationDelegate) {
    appState = UIApplication.sharedApplication().applicationState
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
      if (appState == .Active) {
        delegate?.didEnterRegion(beaconRegion)
        locationManager.startRangingBeaconsInRegion(beaconRegion)
      } else if (appState == .Background) {
        delegate?.didEnterRegion(beaconRegion)
      }
      
    case CLRegionState.Outside:
      Globals.log(" - exited region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      if (appState == .Active) {
        delegate?.didExitRegion(beaconRegion)
        locationManager.stopRangingBeaconsInRegion(beaconRegion)
      } else if (appState == .Background) {
        delegate?.didExitRegion(beaconRegion)
      }
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
    //Globals.log(beacons)
     let key = region.proximityUUID.UUIDString
    
    if beacons.count > 0 {
      var rangedBeacon: CLBeacon! = CLBeacon()
      let battery: Int = Int(rangedBeacon.minor)
      rangedBeacon = beacons[0]
      
      if beaconRegions[key] != nil {
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.SetBattery, object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
      } else {
        beaconRegions[key] = [Constants.Key.Battery: battery, Constants.Key.rssi: rangedBeacon.rssi]
        NSNotificationCenter.defaultCenter().postNotificationName(Constants.Notification.SetBattery, object: nil, userInfo: ["key": key, "minor": rangedBeacon.minor])
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
