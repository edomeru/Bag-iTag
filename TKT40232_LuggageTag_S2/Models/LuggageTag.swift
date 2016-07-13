//
//  BeaconItem.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 25/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import Foundation

class LuggageTag: NSObject {
  var id: Int = 0
  var photo: NSData? = nil
  var name = ""
  var uuid = ""
  var major = ""
  var minor = ""
  var regionState = "unknown"
  var isConnected = false
}