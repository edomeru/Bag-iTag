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
  var beaconRegions: [CLBeaconRegion?]
  var rangedBeacon: CLBeacon! = CLBeacon()
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  init(delegate: TKTCoreLocationDelegate) {
    self.beaconRegions = [CLBeaconRegion?]()
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
    beaconRegions.append(beaconRegion)
    
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
  
  func stopMonitoringBeacon(beaconRegion: CLBeaconRegion?, removeObject: Bool) {
    Globals.log("Stop Monitoring: \((beaconRegion?.proximityUUID.UUIDString)!)")
    locationManager.stopRangingBeaconsInRegion(beaconRegion!)
    locationManager.stopMonitoringForRegion(beaconRegion!)
    locationManager.stopUpdatingLocation()
    
    if(removeObject) {
      let index = getObjectIndex(beaconRegion)
      beaconRegions.removeAtIndex(index)
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
      delegate?.didEnterRegion(beaconRegion)
      //locationManager.startRangingBeaconsInRegion(region as! CLBeaconRegion)
    case CLRegionState.Outside:
      Globals.log(" - exited region \(region.identifier)")
      let beaconRegion = region as! CLBeaconRegion
      delegate?.didExitRegion(beaconRegion)
      //locationManager.stopMonitoringForRegion(region as! CLBeaconRegion)
    default:
      Globals.log(" - unknown region \(region.identifier)")
    }
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    let beaconRegion = region as! CLBeaconRegion
    delegate?.didEnterRegion(beaconRegion)
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    let beaconRegion = region as! CLBeaconRegion
    delegate?.didExitRegion(beaconRegion)
  }
  
  func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {}
  
  func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    Globals.log("rangingBeaconsDidFailForRegion: \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    Globals.log("didFailWithError: \(error)")
  }
  
  // MARK: Private Method
  func getObjectIndex(beaconRegion: CLBeaconRegion?) -> Int {
    for (index, element) in beaconRegions.enumerate() {
      if ((beaconRegion?.proximityUUID.UUIDString == element?.proximityUUID.UUIDString) && (beaconRegion?.identifier == element?.identifier)) {
        return index
      }
    }
    
    return 0
  }
}
