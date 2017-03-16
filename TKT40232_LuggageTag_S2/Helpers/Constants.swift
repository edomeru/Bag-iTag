//
//  Constants.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

struct Constants {
  
  struct UUID {
    static let Identifier = "C2265660-5EC1-4935-9BB3-"
  }
  
  struct Segue {
    static let AddBeacon = "AddBeacon"
    static let EditBeacon = "EditBeacon"
    static let ActivationOptions = "ActivationOptions"
    static let AddPhoto = "AddPhoto"
    static let EnterActivationCode = "EnterActivationCode"
  }
  
  struct Proximity {
    static let Unknown = "unknown"
    static let Inside = "Inside"
    static let Outside = "Outside"
  }
  
  struct Range {
    static let OutOfRange = "Out of Range"
    static let InRange = "In Range"
  }
  
  struct Default {
    static let LuggageName = "Luggage"
    static let LuggageCounter = "LUGGAGE_NAME_COUNTER"
  }
  
  struct Key {
    static let Battery = "battery"
    static let rssi = "rssi"
    static let Proximity = "Proximity"
    static let Exited = "exited"
    static let Initialize = "initialize"
    static let ActivationIdentifier = "activation_identifier"
    static let ActivationCode = "activation_code"
    static let ActivationKey = "activation_key"
    static let ActivatedUUID = "activated_uuid"
  }
  
  struct Notification {
    static let SetBattery = "SetBatteryID"
    static let SetImageRange = "SetImageRangeID"
    static let TransmitActivationKey = "TransmitActivationKeyID"
    static let ActivationSuccessKey = "ActivationSuccessID"
    static let AssignNameToActivatingKey = "AssignNameToActivatingKeyID"
    static let StopActivatingKey = "StopActivatingKeyID"
    static let OnBackgroundAccessEnabled = "OnBackgroundAccessEnabledID"
    static let OnBackgroundAccessDisabled = "OnBackgroundAccessDisabledID"
  }
  
  struct Time {
    static let FifteenSecondsTimeout = 15.0
    static let OneSecond = 1.0
  }
  
}
