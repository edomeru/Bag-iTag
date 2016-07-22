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
  func deleteBeacon(didDeleteItem item: LuggageTag)
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

    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
      if let beaconItem = beaconToEdit {
        let originalStringIndex = beaconItem.uuid.endIndex.advancedBy(-12)
        let originalString = beaconItem.uuid.substringFromIndex(originalStringIndex)
        
        if (isPhotoEdited || (nameTextField.text! != beaconItem.name) || (uuidTextField.text! != originalString)) {
          // Beacon is Edited
          if (beaconItem.isConnected) {
            // Stop Monitoring for this Beacon
            var beaconRegion: CLBeaconRegion?
            beaconRegion = CLBeaconRegion(proximityUUID: NSUUID(UUIDString: beaconItem.uuid)!, identifier: beaconItem.name)
            tktCoreLocation.stopMonitoringBeacon(beaconRegion)
          }
          
          if (isPhotoEdited) {
            beaconItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          beaconItem.name = nameTextField.text!
          beaconItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercaseString)"
          beaconItem.regionState = Constants.Proximity.Outside
          
          delegate?.beaconDetailViewController(self, didFinishEditingItem: beaconItem)
        } else {
          Globals.log("No Changes made in LuggageTag")
          dismissViewControllerAnimated(true, completion: nil)
        }
        
      } else {
        // New Beacon
        let beaconItem = LuggageTag()
        
        if (isPhotoEdited) {
          beaconItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
          beaconItem.photo = nil
        }

        beaconItem.name = nameTextField.text!
        beaconItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercaseString)"
        beaconItem.major = "1"
        beaconItem.minor = "5"
        beaconItem.regionState = Constants.Proximity.Outside
        beaconItem.isConnected = false
        
        delegate?.beaconDetailViewController(self, didFinishAddingItem: beaconItem)
      }
    }
  }
  
  @IBAction func deleteBeacon() {
    if let beaconItem = beaconToEdit {
      delegate?.deleteBeacon(didDeleteItem: beaconItem)
    } else {
      dismissViewControllerAnimated(true, completion: nil)
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
  
  func didEnterRegion(region: CLRegion!) {
    if let connected = beaconToEdit?.isConnected {
      if (region.identifier == beaconToEdit!.name && connected) {
        rangeLabel.text = Constants.Range.InRange
      }
    }
  }
  
  func didExitRegion(region: CLRegion!) {
    if let luggageTag = beaconToEdit?.name {
      if (region.identifier == luggageTag) {
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
  
  private func showAlert(title: String, message: String) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Default, handler: nil)
    alertController.addAction(okAction)
    
    self.presentViewController(alertController, animated: true, completion: nil)
  }
  
  private func validateLuggage() -> Bool {
    if (uuidTextField.text! == "" || uuidTextField.text!.characters.count < 12 || !(uuidTextField.text!.isValidHexNumber())) {
      showAlert(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_identifier_code_invalid", comment: ""))
      
      return false
    }
    
    if (nameTextField.text! == "" || nameTextField.text!.characters.count > 20) {
      showAlert(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_luggage_tag_invalid", comment: ""))
      
      return false
    }
    
    if (!checkIdentifierCodeAvailability()) {
      showAlert(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_identifier_code_exists", comment: ""))
      
      return false
    }
    
    if (!checkTagAvailability()) {
      showAlert(NSLocalizedString("error", comment: ""), message: NSLocalizedString("err_luggage_tag_exists", comment: ""))
      
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
      if (beacon.name == nameTextField.text!) {
        if let item = beaconToEdit {
          if(item.name == beacon.name) {
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
}
