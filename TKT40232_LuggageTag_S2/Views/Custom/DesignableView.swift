//
//  DesignableView.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 02/06/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit

@IBDesignable
class DesignableView : UIView {
  
  var imageView: UIImageView!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    addSubviews()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    addSubviews()
  }
  
  func addSubviews() {
    imageView = UIImageView()
    addSubview(imageView)
  }
  
  override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    
  }
  
  override func layoutSubviews() {
    imageView.frame = self.bounds
    imageView.contentMode = UIViewContentMode.ScaleAspectFit
  }
  
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
      layer.borderColor = borderColor?.CGColor
    }
  }
  
  @IBInspectable var image: UIImage? {
    didSet { imageView.image = image }
  }
}