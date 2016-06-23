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
  func didEnterRegion(region: CLRegion!)
  func didExitRegion(region: CLRegion!)
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion)
  //func onError(error: NSError)
}


class TKTCoreLocation: NSObject, CLLocationManagerDelegate {
  
  var locationManager: CLLocationManager!
  var beaconRegion: CLBeaconRegion?
  var rangedBeacon: CLBeacon! = CLBeacon()
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  init(delegate: TKTCoreLocationDelegate) {
    super.init()
    self.delegate = delegate
    self.locationManager = CLLocationManager()
    self.locationManager!.delegate = self
  }
  
  // MARK: Action Method
  func startMonitoring(beaconRegion: CLBeaconRegion?) {
    print("Start monitoring")
    pendingMonitorRequest = true
    self.beaconRegion = beaconRegion
    
    switch CLLocationManager.authorizationStatus() {
    case .NotDetermined:
      print("NotDetermined")
      locationManager.requestAlwaysAuthorization()
    case .Restricted, .Denied, .AuthorizedWhenInUse:
      print(".Restricted, .Denied, .AuthorizedWhenInUse")
      delegate?.onBackgroundLocationAccessDisabled()
    case .AuthorizedAlways:
      print(".AuthorizedAlways")
      locationManager!.startMonitoringForRegion(beaconRegion!)
      pendingMonitorRequest = false
    }
  }
  
  func stopMonitoring() {
    print("Stop monitoring")
    pendingMonitorRequest = false
    locationManager.stopRangingBeaconsInRegion(beaconRegion!)
    locationManager.stopMonitoringForRegion(beaconRegion!)
    locationManager.stopUpdatingLocation()
    beaconRegion = nil
    delegate?.didStopMonitoring()
  }
  
  func stopMonitoringBeacon(beaconRegion: CLBeaconRegion?) {
    locationManager.stopRangingBeaconsInRegion(beaconRegion!)
    locationManager.stopMonitoringForRegion(beaconRegion!)
    locationManager.stopUpdatingLocation()
    
  }
  
  // MARK: CLLocationManagerDelegate Method
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    print("didChangeAuthorizationStatus \(status)")
    if (status == .AuthorizedWhenInUse || status == .AuthorizedAlways) && beaconRegion != nil {
      if pendingMonitorRequest {
        locationManager!.startMonitoringForRegion(beaconRegion!)
        pendingMonitorRequest = false
      }
      locationManager!.startUpdatingLocation()
    }
  }
  
  func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
    print("didStartMonitoringForRegion \(region.identifier)")
    delegate?.didStartMonitoring()
    locationManager.requestStateForRegion(region)
  }
  
  func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
    print("monitoringDidFailForRegion - \(manager)")
    print("monitoringDidFailForRegion - \(region)")
    print("monitoringDidFailForRegion - \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
    if state == CLRegionState.Inside {
      print(" - entered region \(region.identifier)")
      delegate?.didEnterRegion(region)
      //locationManager.startRangingBeaconsInRegion(beaconRegion!)
    } else {
      print(" - exited region \(region.identifier)")
      //locationManager.stopRangingBeaconsInRegion(beaconRegion!)
    }
  }
  
  func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
    //print("didEnterRegion - \(region.identifier)")
    delegate?.didEnterRegion(region)
  }
  
  func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
    //print("didExitRegion - \(region.identifier)")
    delegate?.didExitRegion(region)
  }
  
  func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
    //print(beacons)
    /*if (beacons.count > 0) {
      delegate?.didRangeBeacon(manager, didRangeBeacons: beacons, inRegion: region)
    }*/
  }
  
  func locationManager(manager: CLLocationManager, rangingBeaconsDidFailForRegion region: CLBeaconRegion, withError error: NSError) {
    print("rangingBeaconsDidFailForRegion \(error)")
  }
  
  func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    print("didFailWithError \(error)")
    if (error.code == CLError.Denied.rawValue) {
      stopMonitoring()
    }
  }
}
