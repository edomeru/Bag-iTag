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
  
}
