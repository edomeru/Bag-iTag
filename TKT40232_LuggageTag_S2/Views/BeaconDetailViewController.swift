//
//  BeaconDetailViewController.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 26/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import Foundation

extension String {
  
  func isValidHexNumber() -> Bool {
    let chars = NSCharacterSet(charactersInString: "0123456789ABCDEF").invertedSet
    if let _ = self.uppercaseString.rangeOfCharacterFromSet(chars) {
      return false
    }
    return true
  }
  
}

protocol BeaconDetailViewControllerDelegate: NSObjectProtocol {
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishAddingItem item: LuggageTag)
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishEditingItem item: LuggageTag)
  func stopMonitoring(didStopMonitoring item: LuggageTag)
  func didBluetoothPoweredOff(didPowerOff item: LuggageTag)
}

class BeaconDetailViewController: UIViewController, CBCentralManagerDelegate, UITextFieldDelegate, TKTCoreLocationDelegate, ModalViewControllerDelegate {

  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var uuidTextField: UITextField!
  @IBOutlet weak var imgButton: UIButton!
  @IBOutlet weak var rangeLabel: UILabel!
  
  var centralManager: CBCentralManager!
  
  var tktCoreLocation: TKTCoreLocation!
  
  weak var delegate: BeaconDetailViewControllerDelegate?
  
  var beaconReference: [LuggageTag]?
  var beaconToEdit: LuggageTag?
  var isPhotoEdited = false
  var trimmedName: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    formatNavigationBar()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil);
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil);
    
    centralManager = CBCentralManager(delegate: self, queue: nil)
    tktCoreLocation = TKTCoreLocation(delegate: self)
    
    if let item = beaconToEdit {
      if (item.photo != nil) {
        imgButton.setImage(UIImage(data: item.photo!), forState: .Normal)
        imgButton.imageView?.contentMode = UIViewContentMode.Center
      }
      
      if (item.regionState == "Inside") {
        rangeLabel.text = Constants.Range.InRange
      } else {
        rangeLabel.text = Constants.Range.OutOfRange
      }
      
      nameTextField.text = item.name
      
      let stringIndex = item.uuid.endIndex.advancedBy(-12)
      uuidTextField.text = item.uuid.substringFromIndex(stringIndex)
    } else {
      rangeLabel.hidden = true
    }
    
    nameTextField.delegate = self
    uuidTextField.delegate = self
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let controller = segue.destinationViewController as! ModalViewController
    controller.delegate = self
  }
  
  // MARK: UITextFieldDelegate Methods
  func textFieldShouldReturn(textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
    
    let currentCharacterCount = textField.text?.characters.count ?? 0
    
    if (range.length + range.location > currentCharacterCount){
      return false
    }
    let newLength = currentCharacterCount + string.characters.count - range.length
    
    if (textField.tag == 1000) {
      return newLength <= 20 // Character Limit for Luggage Tag
    } else {
      return newLength <= 12 // Character Limit for Identifier Code
    }
  }
  
  // MARK: Action Methods
  @IBAction func saveBeacon() {
    nameTextField.resignFirstResponder()
    uuidTextField.resignFirstResponder()
    
    trimmedName = nameTextField.text!.stringByTrimmingCharactersInSet(
      NSCharacterSet.whitespaceAndNewlineCharacterSet()
    )
    
    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
      if let luggageItem = beaconToEdit {
    
        let originalStringIndex = luggageItem.uuid.endIndex.advancedBy(-12)
        let originalString = luggageItem.uuid.substringFromIndex(originalStringIndex)
        
        if (isPhotoEdited || (nameTextField.text! != luggageItem.name) || (uuidTextField.text! != originalString)) {
          // Beacon is Edited
          
          // Check/Get Luggage's Name
          assignLuggageName()
          
          if (luggageItem.isConnected) {
            // Stop Monitoring for this Beacon
            delegate?.stopMonitoring(didStopMonitoring: luggageItem)
          }
          
          if (isPhotoEdited) {
            luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          luggageItem.name = trimmedName!
          luggageItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercaseString)"
          luggageItem.regionState = Constants.Proximity.Outside
          
          delegate?.beaconDetailViewController(self, didFinishEditingItem: luggageItem)
        } else {
          Globals.log("No Changes made in LuggageTag")
          dismissViewControllerAnimated(true, completion: nil)
        }

      } else {
        // Check/Get Luggage's Name
        assignLuggageName()
        
        //New Luggage
        let luggageItem = LuggageTag()
        
        if (isPhotoEdited) {
          luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
          luggageItem.photo = nil
        }
        
        luggageItem.name = trimmedName!
        luggageItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercaseString)"
        luggageItem.major = "1"
        luggageItem.minor = "5"
        luggageItem.regionState = Constants.Proximity.Outside
        luggageItem.isConnected = false
        
        delegate?.beaconDetailViewController(self, didFinishAddingItem: luggageItem)
      }
    }
  }
  
  // MARK: ModalViewControllerDelegate
  func didFinishPickingMediaWithInfo(image: UIImage) {
    isPhotoEdited = true
    imgButton.setImage(image, forState: .Normal)
    imgButton.imageView?.contentMode = UIViewContentMode.Center
  }
  
  // MARK: Private Methods
  private func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.translucent = true
  }
  
  // MARK: CBCentralManagerDelegate Methods
  func centralManagerDidUpdateState(central: CBCentralManager) {
    switch (central.state) {
    case .PoweredOn:
      break
    case .PoweredOff:
      if let luggageTag = beaconToEdit {
        luggageTag.regionState = Constants.Proximity.Outside
        rangeLabel.text = Constants.Range.OutOfRange
        delegate?.didBluetoothPoweredOff(didPowerOff: luggageTag)
      }
    default:
      break
    }
  }
  
  // MARK: TKTCoreLocationDelegate
  func onBackgroundLocationAccessDisabled() {}
  
  func didStartMonitoring() {}
  
  func didStopMonitoring() {}
  
  func monitoringDidFail() {}
  
  func didEnterRegion(region: CLBeaconRegion) {
    if let luggageTag = beaconToEdit {
      let connected = luggageTag.isConnected
      if (region.identifier == luggageTag.name && region.proximityUUID.UUIDString == luggageTag.uuid && connected) {
        rangeLabel.text = Constants.Range.InRange
      }
    }
  }
  
  func didExitRegion(region: CLBeaconRegion) {
    if let luggageTag = beaconToEdit {
      if(region.identifier == luggageTag.name && region.proximityUUID.UUIDString == luggageTag.uuid) {
        rangeLabel.text = Constants.Range.OutOfRange
      }
    }
  }
  
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {}
  
  func keyboardWillShow(sender: NSNotification) {
    self.view.frame.origin.y = -150
  }
  
  func keyboardWillHide(sender: NSNotification) {
    self.view.frame.origin.y = 0
  }
  
  private func showConfirmation(title: String, message: String) {
    let actions = [
      UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .Cancel) { (action) in
        Globals.log("Cancel Adding/Editing Luggage")
        self.dismissViewControllerAnimated(true, completion: nil)
      },
      UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .Default, handler: nil)
    ]
    
    Globals.showAlert(self, title: title, message: message, animated: true, completion: nil, actions: actions)
  }
  
  private func showError(title: String, message: String) {
    let okAction = [UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Cancel, handler: nil)]
    Globals.showAlert(self, title: title, message: message, animated: true, completion: nil, actions: okAction)
  }
  
  private func assignLuggageName() {
    if (trimmedName! == "") {
      let prefs = NSUserDefaults.standardUserDefaults()
      
      if let key = prefs.objectForKey(Constants.Default.LuggageCounter) {
        if let counter = key as? Int {
          var num = counter
          
          repeat {
            num = num + 1
            trimmedName! = "\(Constants.Default.LuggageName) \(num)"
          } while checkTagAvailability()
          
          prefs.setInteger(num, forKey: Constants.Default.LuggageCounter)
          prefs.synchronize()
        }
      } else {
        trimmedName! = Constants.Default.LuggageName
        
        prefs.setInteger(1, forKey: Constants.Default.LuggageCounter)
        prefs.synchronize()
      }
    }
    
  }
  
  private func validateLuggage() -> Bool {
    if (uuidTextField.text! == "") {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      
      return false
    }
     
    if (uuidTextField.text!.characters.count < 12 || !(uuidTextField.text!.isValidHexNumber())) {
      showError(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_identifier_code_invalid", comment: ""))
      
      return false
    }
    
    if (!checkIdentifierCodeAvailability()) {
      showError(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_identifier_code_exists", comment: ""))
      
      return false
    }
    
    if (checkTagAvailability()) {
      showError(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_luggage_tag_exists", comment: ""))
      
      return false
    }

    return true
  }
  
  func checkIdentifierCodeAvailability() -> Bool {
    for beacon in beaconReference! {
      if (beacon.uuid == ("\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercaseString)")) {
        if let item = beaconToEdit {
          if (item.uuid == beacon.uuid) {
            continue
          } else {
            return false
          }
        }
        
        return false
      }
    }
    
    return true
  }
  
  func checkTagAvailability() -> Bool {
    
    for beacon in beaconReference! {
      if (beacon.name == trimmedName!) {
        if let item = beaconToEdit {
          if(item.name == beacon.name) {
            continue
          } else {
            return true
          }
        }
        
        return true
      }
    }
    
    return false
  }
}
