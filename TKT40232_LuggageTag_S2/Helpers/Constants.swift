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
    static let LuggageName = "LuggageTag"
    static let LuggageCounter = "LUGGAGE_NAME_COUNTER"
  }
  
}
