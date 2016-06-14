//
//  BeaconItem.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 25/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import Foundation

class BeaconModel: NSObject {
  var id: Int = 0
  var photo: NSData? = nil
  var name = ""
  var UUID = ""
  var major = ""
  var minor = ""
  var proximity = "unknown"
  var isConnected = false
}