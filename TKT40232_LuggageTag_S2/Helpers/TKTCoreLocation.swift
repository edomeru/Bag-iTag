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
  func onBackgroundLocationAccessDisabled(_ accessCode: Int32)
  func didStartMonitoring()
  func didStopMonitoring()
  func monitoringDidFail()
  func didEnterRegion(_ region: CLBeaconRegion)
  func didExitRegion(_ region: CLBeaconRegion)
  func didRangeBeacon(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion)
  
}

var timer = Timer()

class TKTCoreLocation: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
  
  var locationManager: CLLocationManager!
  var peripheralManager: CBPeripheralManager!
  var beaconRegion: CLBeaconRegion?
  var monitoredRegions: [String: String]
  var beaconRegions: [String: [String: Int]]
  var pendingMonitorRequest: Bool = false
  
  weak var delegate: TKTCoreLocationDelegate?
  
  
  
  var activationName: String?
  var activationCode: String?
  var activationKey: String?
  var activatedBeaconUUID: String?
  
  init(delegate: TKTCoreLocationDelegate) {
    self.beaconRegions = [String: [String: Int]]()
    monitoredRegions = [String: String]()
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
    monitoredRegions[(beaconRegion?.proximityUUID.uuidString)!] = beaconRegion?.identifier
    
    switch CLLocationManager.authorizationStatus() {
    case .notDetermined:
      Globals.log("authorizationStatus: .NotDetermined")
      delegate?.onBackgroundLocationAccessDisabled(CLLocationManager.authorizationStatus().rawValue)
    case .restricted, .denied, .authorizedWhenInUse:
      Globals.log("authorizationStatus: .Restricted, .Denied, .AuthorizedWhenInUse")
      delegate?.onBackgroundLocationAccessDisabled(CLLocationManager.authorizationStatus().rawValue)
    case .authorizedAlways:
      Globals.log("authorizationStatus: .AuthorizedAlways")
      locationManager!.startMonitoring(for: beaconRegion!)
      pendingMonitorRequest = false
    }
  }
  
  func stopMonitoringBeacon(_ beaconRegion: CLBeaconRegion?, key: String) {
    Globals.log("Stop Monitoring stopMonitoringBeacon: \((beaconRegion?.proximityUUID.uuidString)!)")
    locationManager.stopRangingBeacons(in: beaconRegion!)
    locationManager.stopMonitoring(for: beaconRegion!)
    locationManager.stopUpdatingLocation()
    
    if (key != "") {
      if let removedValue = monitoredRegions.removeValue(forKey: key) {
        Globals.log("Removed Dictionary: \(removedValue)")
      }
    }
    
    /*if(key != "") {
      if let removedValue = beaconRegions.removeValue(forKey: key) {
        Globals.log("Removed Dictionary: \(removedValue)")
      }
    }*/
  }
    
    
  
  func broadcastActivationKey(activationCode: String) {
    Globals.log("broadcastActivationKey______\(activationCode)")
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
    
     Globals.log("acDecimal1\(acDecimal1)")
    //////EDMER
   
    let tensOfSeconds: Int? = numberOfDays(days: 7)
    let hexValue:String? = convertToHex(hexValue: tensOfSeconds!)
    var uIntHex1: UInt8 = 0
    var uIntHex2: UInt8 = 0
    
    
    if hexValue != nil {
        let endIndex = hexValue?.index((hexValue?.endIndex)!, offsetBy: -2)
        let acDecima20 = hexValue?.substring(to: endIndex!)
        
        
        uIntHex1 = UInt8(strtoul(acDecima20, nil, 16))
        
    }
   
    let last_two = hexValue?.substring(from:(hexValue?.index((hexValue?.endIndex)!, offsetBy: -2))!)

    uIntHex2 = UInt8(strtoul(last_two, nil, 16))

    let data: Data = Data(bytes: [0x00, 0x00, 0x00, 0x00, 0x00, uIntHex1, uIntHex2, 0x00, 0x00, acDecimal6, acDecimal5, acDecimal4, acDecimal3, acDecimal2, acDecimal1, 0x00])
   
    
    Globals.log("HELLO_SCAN______\(data)")
    let cbuuid = CBUUID(data: data)
    Globals.log("Hcbuuid_____\(cbuuid)")
    let service = [cbuuid]
    let advertisingDic = Dictionary(dictionaryLiteral: (CBAdvertisementDataServiceUUIDsKey, service))
    
    let activationKey = data.hexEncodedString().uppercased().substring(from: 18)
    
    self.activationCode = activationCode
    self.activationKey = activationKey
    Globals.log("activationKey\(activationKey)")
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
    
    // Note: .authorizedAlways == 3
    if (CLLocationManager.authorizationStatus().rawValue == 3) {
         Globals.log("authorizedAlways____")
      NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil, userInfo: nil) //KUNG pinayagan ni app na magscan ng mga beacon or permission
        Globals.log("PERIPHERAL START  \(advertisingDic)")
        
      peripheralManager.startAdvertising(advertisingDic)// start ng Broadcasting
        Globals.log("PERIPHERAL STARTfsfafdabklfi99   \(advertisingDic)")
      NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil, userInfo: [Constants.Key.ActivatedUUID: identifier, Constants.Key.ActivationKey: activationKey])
        //
        Globals.log("TIMER")
      timer = Timer.scheduledTimer(timeInterval: Constants.Time.FifteenSecondsTimeout, target: self, selector: #selector(TKTCoreLocation.stopAdvertising), userInfo: nil, repeats: false)
    } else {
      delegate?.onBackgroundLocationAccessDisabled(CLLocationManager.authorizationStatus().rawValue)
    }
  }///  END OF broadcastActivationKey
    

    func numberOfDays(days:Int)-> Int{
        
        return days*24*60*60/10
    }
    
    
    func convertToHex(hexValue:Int)->String{
    
        let st = String(format:"%2X", hexValue)
     
        return st
    }
    
    
    
  func stopAdvertising() {
    Globals.log("Stop Advertising STOP HERE")
    peripheralManager.stopAdvertising()
    Globals.log("activatedBeaconUUID  \(activatedBeaconUUID)")
    if let activatdBeaconUuiD = activatedBeaconUUID {
        Globals.log("INSIDE stopAdvertising \(activatdBeaconUuiD)")
    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil, userInfo: [Constants.Key.ActivatedUUID: activatdBeaconUuiD])
    }
     Globals.log("OUTSIDE IF stopAdvertising ")
    activationCode = nil
    activationKey = nil
    activatedBeaconUUID = nil
  }
  
  // MARK: CLLocationManagerDelegate Method
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    Globals.log("didChangeAuthorizationStatus: \(status)")
    //if (status == .authorizedWhenInUse || status == .authorizedAlways) && beaconRegion != nil {
    if (status == .authorizedAlways && beaconRegion != nil) {
      if pendingMonitorRequest {
        locationManager!.startMonitoring(for: beaconRegion!)
        pendingMonitorRequest = false
      }
      locationManager!.startUpdatingLocation()
    }
    
    if let _ = activatedBeaconUUID, let _ = activationKey, let ac = activationCode {
      if (status == .authorizedAlways) {
        // We are Activing a Beacon so Display the Shake Alert Dialog
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil, userInfo: nil)
        self.broadcastActivationKey(activationCode: ac)
      } else {
      
      }
    } else {
      beaconRegion = nil
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    Globals.log("didStartMonitoringForRegion BWAHAH: \(region.identifier)")
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
      
      if let abUUID = activatedBeaconUUID, let ak = activationKey, let ac = activationCode {
        // Success Activating the Beacon from Deep Sleep
         Globals.log("Stop UUID \(abUUID)  activationKey  \(ak)  activationCode  \(ac) ")
        if timer.isValid {
          timer.invalidate()
          
          Globals.log("Stop Advertising...")
          peripheralManager.stopAdvertising()
            
        }
        

        let myDict: [String: Any] = [ Constants.Key.ActivatedUUID: abUUID, Constants.Key.ActivationKey: ak,Constants.Key.ActivationCode: ac]
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.ENTER_REGION), object: nil, userInfo: myDict)
        
//        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil, userInfo: [Constants.Key.ActivationIdentifier: beaconRegion.identifier, Constants.Key.ActivatedUUID: abUUID, Constants.Key.ActivationKey: ak, Constants.Key.ActivationCode: ac])    // SAVING TO DATABASE
        
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
    
    deinit {
        Globals.log("DE INIT TKTCoreLocation")
        
        NotificationCenter.default.removeObserver(self)
        
    }
}
