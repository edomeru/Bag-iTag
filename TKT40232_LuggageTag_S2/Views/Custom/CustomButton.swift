//
//  CustomButton.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 02/06/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit

@IBDesignable
class CustomButton: UIButton {
  
  @IBInspectable var cornerRadius: CGFloat = 0 {
    didSet {
      layer.cornerRadius = cornerRadius
      layer.masksToBounds = cornerRadius > 0
    }
  }
  
  @IBInspectable var borderWidth: CGFloat = 0 {
    didSet {
      layer.borderWidth = borderWidth
    }
  }
  
  @IBInspectable var borderColor: UIColor? {
    didSet {
      layer.borderColor = borderColor?.cgColor
    }
  }
}
