//
//  TKTCoreLocation.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import CoreLocation
import CoreBluetooth
import Foundation

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


class TKTCoreLocation: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
  
  var locationManager: CLLocationManager!
  var peripheralManager: CBPeripheralManager!
  var beaconRegion: CLBeaconRegion?
  var beaconRegions: [String: [String: Int]]
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  var timer = Timer()
  
  var activationCode: String?
  var activationKey: String?
  var activatedBeaconUUID: String?
  
  init(delegate: TKTCoreLocationDelegate) {
    self.beaconRegions = [String: [String: Int]]()
    super.init()
    self.delegate = delegate
    self.locationManager = CLLocationManager()
    self.locationManager!.delegate = self
    peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
  }

  // MARK: CBPeripheralManagerDelegate Delegate
  public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    switch (peripheral.state) {
    case .poweredOn:
      Globals.log("Peripheral Manager powered on.")
    case .poweredOff:
      Globals.log("Peripheral Manager powered off.")
      break
    default:
      Globals.log("Peripheral Manager state changed: \(peripheral.state)")
      break
    }
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
  
  func broadcastActivationKey(activationCode: String) {
    let chars = Array(activationCode.characters)
    let byteArray: [UInt8] = stride(from: 0, to: chars.count, by: 2).map() {
      UInt8(strtoul(String(chars[$0 ..< min($0 + 2, chars.count)]), nil, 16))
    }
    
    let acDecimal1 = byteArray[5] ^ byteArray[4]
    let acDecimal2 = byteArray[4] ^ byteArray[3]
    let acDecimal3 = byteArray[3] ^ byteArray[5]
    let acDecimal4 = byteArray[2] ^ byteArray[4]
    let acDecimal5 = byteArray[1] ^ byteArray[5]
    let acDecimal6 = byteArray[0] ^ byteArray[4]
    
    let data: Data = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, acDecimal6, acDecimal5, acDecimal4, acDecimal3, acDecimal2, acDecimal1, 0x00])
    let cbuuid = CBUUID(data: data)
    let service = [cbuuid]
    let advertisingDic = Dictionary(dictionaryLiteral: (CBAdvertisementDataServiceUUIDsKey, service))
    
    peripheralManager.startAdvertising(advertisingDic)
    
    let activationKey = data.hexEncodedString().uppercased().substring(from: 18)
    
    self.activationCode = activationCode
    self.activationKey = activationKey
    
    var uuidString = ""
    uuidString.append(chars[10])
    uuidString.append(chars[11])
    uuidString.append(chars[8])
    uuidString.append(chars[9])
    uuidString.append(chars[6])
    uuidString.append(chars[7])
    uuidString.append(chars[4])
    uuidString.append(chars[5])
    uuidString.append(chars[2])
    uuidString.append(chars[3])
    uuidString.append(chars[0])
    uuidString.append(chars[1])
    
    let identifier = "\(Constants.UUID.Identifier)\(uuidString)"
    self.activatedBeaconUUID = identifier
    var beaconRegion: CLBeaconRegion?
    beaconRegion = CLBeaconRegion(proximityUUID: UUID(uuidString: identifier)!, identifier: "")
    beaconRegion!.notifyEntryStateOnDisplay = true
    beaconRegion!.notifyOnEntry = true
    beaconRegion!.notifyOnExit = true
    
    startMonitoring(beaconRegion)
    
    timer = Timer.scheduledTimer(timeInterval: Constants.Time.FifteenSecondsTimeout, target: self, selector: #selector(TKTCoreLocation.stopAdvertising), userInfo: nil, repeats: false)
  }
  
  func stopAdvertising() {
    Globals.log("Stop Advertising")
    peripheralManager.stopAdvertising()
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
      //locationManager.startRangingBeacons(in: beaconRegion)
      delegate?.didEnterRegion(beaconRegion)
      
      if let ac = activationCode, let ak = activationKey, let abUUID = activatedBeaconUUID {
        // Success Activating the Beacon from Deep Sleep
        
        if timer.isValid {
          timer.invalidate()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil, userInfo: [Constants.Key.ActivationCode: ac, Constants.Key.ActivationKey: ak, Constants.Key.ActivatedUUID: abUUID])
        
        activationCode = nil
        activationKey = nil
        activatedBeaconUUID = nil
      }
      
    case CLRegionState.outside:
      Globals.log(" - exited region \(region.identifier)")
      
      let beaconRegion = region as! CLBeaconRegion
      //locationManager.stopRangingBeacons(in: beaconRegion)
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
    //NSLog("BEACON: \(beacons)", "")
    //NSLog("REGION: \(region)", "")
    
    let key = region.proximityUUID.uuidString
    
    if beacons.count > 0 {
      //var rangedBeacon: CLBeacon! = CLBeacon()
      //rangedBeacon = beacons[0]
      let battery: Int = Int(beacons.first!.minor)
      let absRssiValue = abs(beacons.first!.rssi)
      var proximityCode: Int = 0
      var rangeImage: String = ""
      
      switch beacons.first!.proximity {
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
          NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetBattery), object: nil, userInfo: ["key": key, "minor": beacons.first!.minor])
        }
      } else {
        beaconRegions[key] = [Constants.Key.Battery: battery, Constants.Key.rssi: absRssiValue, Constants.Key.Proximity: proximityCode]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetImageRange), object: nil, userInfo: ["key": key, "rangeImage": rangeImage])
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SetBattery), object: nil, userInfo: ["key": key, "minor": beacons.first!.minor])
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
