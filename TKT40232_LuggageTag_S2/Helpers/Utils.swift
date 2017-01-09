//
//  Utils.swift
//  TKT40232_LuggageTag_S2
//
//  Created by PhTktimac1 on 05/01/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import Foundation

extension String {
  var asciiArray: [UInt32] {
    return unicodeScalars.filter{$0.isASCII}.map{$0.value}
  }
  
  func index(from: Int) -> Index {
    return self.index(startIndex, offsetBy: from)
  }
  
  func substring(from: Int) -> String {
    let fromIndex = index(from: from)
    return substring(from: fromIndex)
  }
  
  func substring(to: Int) -> String {
    let toIndex = index(from: to)
    return substring(to: toIndex)
  }
  
  func substring(with r: Range<Int>) -> String {
    let startIndex = index(from: r.lowerBound)
    let endIndex = index(from: r.upperBound)
    return substring(with: startIndex..<endIndex)
  }
}
extension Character {
  var asciiValue: UInt32? {
    return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
  }
}

extension Data {
  func hexEncodedString() -> String {
    return map { String(format: "%02hhx", $0) }.joined()
  }
}
