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
  
  @IBOutlet var photo: CustomButton!
  @IBOutlet var name: UILabel!
  @IBOutlet var connection: CustomDetectionView!
  @IBOutlet var customSwitch: SevenSwitch!
  @IBOutlet var battery: UILabel!
  
  weak var delegate: CustomTableCellDelegate?
  
  func setupWithModel(model: LuggageTag) {
    if (model.photo != nil) {
      photo.setImage(UIImage(data: model.photo!)!, forState: .Normal)
      photo.imageView?.contentMode = UIViewContentMode.Center
    } else {
      photo.setImage(UIImage(named: "luggage_default"), forState: .Normal)
    }
    
    battery.text = "\(model.minor)%"
    
    if (model.regionState == "Outside" || model.regionState == "unknown") {
      connection.image = UIImage(named: "off_range")
      battery.hidden = true
    } else {
      connection.image = UIImage(named: "in_range")
      battery.hidden = (battery.text! == "-1%") ? true : false
    }
    
    photo.userInteractionEnabled = false
    
    name.text = model.name
  
    customSwitch.setOn(model.isConnected, animated: false)
    customSwitch.offLabel.text = "OFF"
    customSwitch.offLabel.font = UIFont(name: "Gadugi-Bold", size: 15)
    customSwitch.offLabel.textColor = UIColor(red: 211, green: 31, blue: 38)
    customSwitch.onLabel.text = "ON"
    customSwitch.onLabel.font = UIFont(name: "Gadugi-Bold", size: 15)
    customSwitch.onLabel.textColor = UIColor(red: 60, green: 163, blue: 62)
  }
  
  @IBAction func valueChanged(sender: AnyObject) {
    delegate?.didTappedSwitchCell(self)
  }
}
