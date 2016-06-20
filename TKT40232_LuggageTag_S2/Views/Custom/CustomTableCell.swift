//
//  CustomTableCell.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 24/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit


extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    let newRed = CGFloat(red)/255
    let newGreen = CGFloat(green)/255
    let newBlue = CGFloat(blue)/255
    
    self.init(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
  }
}

protocol CustomTableCellDelegate: NSObjectProtocol {
  func didTappedSwitchCell(cell: CustomTableCell)
}

class CustomTableCell: UITableViewCell {
  
  
  //@IBOutlet var photo: DesignableView!
  @IBOutlet var photo: CustomButton!
  @IBOutlet var name: UILabel!
  @IBOutlet var connection: DesignableView!
  @IBOutlet var customSwitch: SevenSwitch!
  
  weak var delegate: CustomTableCellDelegate?
  
  func setupWithModel(model: BeaconModel) {
    //let size = CGSize(width: 150, height: 150)
    if (model.photo != nil) {
      //photo.image = scaleImage(UIImage(data: model.photo!)!, toSize: size)
      photo.setImage(UIImage(data: model.photo!)!, forState: .Normal)
      photo.imageView?.contentMode = UIViewContentMode.Center
    } else {
      //photo.image = UIImage(named: "luggage_default")
      photo.setImage(UIImage(named: "luggage_default"), forState: .Normal)
    }
    
    if (model.proximity == "Outside" || model.proximity == "unknown") {
      connection.image = UIImage(named: "off_range")
    } else {
      connection.image = UIImage(named: "in_range")
    }
    
    photo.userInteractionEnabled = false
    
    name.text = model.name
    
    customSwitch.setOn(!model.isConnected, animated: false)
    customSwitch.offLabel.text = "ON"
    customSwitch.offLabel.font = UIFont(name: "Gadugi-Bold", size: 15)
    customSwitch.offLabel.textColor = UIColor(red: 60, green: 163, blue: 62)
    customSwitch.onLabel.text = "OFF"
    customSwitch.onLabel.font = UIFont(name: "Gadugi-Bold", size: 15)
    customSwitch.onLabel.textColor = UIColor(red: 211, green: 31, blue: 38)
  }
  
  @IBAction func valueChanged(sender: AnyObject) {
    delegate?.didTappedSwitchCell(self)
  }
  
  func scaleImage(image: UIImage, toSize newSize: CGSize) -> (UIImage) {
    let newRect = CGRectIntegral(CGRectMake(0,0, newSize.width, newSize.height))
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0)
    let context = UIGraphicsGetCurrentContext()
    CGContextSetInterpolationQuality(context, .High)
    let flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height)
    CGContextConcatCTM(context, flipVertical)
    CGContextDrawImage(context, newRect, image.CGImage)
    let newImage = UIImage(CGImage: CGBitmapContextCreateImage(context)!)
    UIGraphicsEndImageContext()
    return newImage
  }
}
