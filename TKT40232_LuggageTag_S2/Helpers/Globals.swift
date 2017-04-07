//
//  Globals.swift
//  TKT40232_LuggageTag_S2
//
//  Created by PhTktimac1 on 22/07/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//
import UIKit

class Globals {
  
  // This function is use for Logging
  static func log(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    #if DEBUG
    
    var idx = items.startIndex
    let endIdx = items.endIndex
    
    repeat {
      Swift.print(items[idx], separator: separator, terminator: idx == (endIdx - 1) ? terminator : separator)
      idx += 1
    }
    while idx < endIdx
    
    #endif
  }
  
  // This function is use for displaying Alert Box
  static func showAlert(_ viewController: UIViewController, title: String, message: String, animated: Bool, completion: (() -> Void)?, actions: [UIAlertAction]) {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    
    for action in actions {
      alertController.addAction(action)
    }
    
    viewController.present(alertController, animated: animated, completion: completion)
  }
  
  // This function is use for generating Activation Code
  static func generateActivationCode(code: String) -> String {
    var BTAddress:Int64 = 0
    var powIndex = 0
    
    for char in code.characters.reversed() {
      let characterString = "\(char)"
      
      if let asciiValue = Character(characterString).asciiValue {
        BTAddress += Int64(asciiValue - 96) * Int64("\(pow(26, powIndex))")!
        powIndex += 1
      }
    }
    
    let hexString = String(BTAddress, radix: 16, uppercase: true)
    
    return hexString
  }
  
  static func generateActivationKey(code: String) -> String {
    let chars = Array(code.characters)
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
    
    let activationKey = data.hexEncodedString().uppercased().substring(from: 18)
    
    return activationKey.uppercased()
  }
  
  static func generateUUID(code: String) -> String {
    let chars = Array(code.characters)
    
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
    
    return "\(Constants.UUID.Identifier)\(uuidString)"
  }
    
    
  
}
