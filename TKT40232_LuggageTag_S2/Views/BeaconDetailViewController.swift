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
    let chars = CharacterSet(charactersIn: "0123456789ABCDEF").inverted
    if let _ = self.uppercased().rangeOfCharacter(from: chars) {
      return false
    }
    return true
  }
  
}

protocol BeaconDetailViewControllerDelegate: NSObjectProtocol {
  func beaconDetailViewController(_ controller: BeaconDetailViewController, didFinishAddingItem item: LuggageTag)
  func beaconDetailViewController(_ controller: BeaconDetailViewController, didFinishEditingItem item: LuggageTag)
  func stopMonitoring(didStopMonitoring item: LuggageTag)
  func didBluetoothPoweredOff(didPowerOff item: LuggageTag)
}

class BeaconDetailViewController: UIViewController, CBCentralManagerDelegate, UITextFieldDelegate, ModalViewControllerDelegate {

  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var uuidTextField: UITextField!
  @IBOutlet weak var imgButton: UIButton!
  @IBOutlet weak var rangeLabel: UILabel!
  
  var centralManager: CBCentralManager!
  
  weak var delegate: BeaconDetailViewControllerDelegate?
  
  var beaconReference: [LuggageTag]?
  var beaconToEdit: LuggageTag?
  var isPhotoEdited = false
  var trimmedName: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    formatNavigationBar()
    
    // NSNotification Observer for Keyboard
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    
    // NSNotification Observer for TKTCoreLocation in ListView
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.setEnterRegion(_:)), name: NSNotification.Name(rawValue: Constants.Proximity.Inside), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.setExitRegion(_:)), name: NSNotification.Name(rawValue: Constants.Proximity.Outside), object: nil)
    
    centralManager = CBCentralManager(delegate: self, queue: nil)
    
    if let item = beaconToEdit {
      if (item.photo != nil) {
        imgButton.setImage(UIImage(data: item.photo! as Data), for: UIControlState())
        imgButton.imageView?.contentMode = UIViewContentMode.center
      }
      
      if (item.regionState == "Inside") {
        rangeLabel.text = Constants.Range.InRange
      } else {
        rangeLabel.text = Constants.Range.OutOfRange
      }
      
      nameTextField.text = item.name
      
      let stringIndex = item.uuid.characters.index(item.uuid.endIndex, offsetBy: -12)
      uuidTextField.text = item.uuid.substring(from: stringIndex)
    } else {
      rangeLabel.isHidden = true
    }
    
    nameTextField.delegate = self
    uuidTextField.delegate = self
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let controller = segue.destination as! ModalViewController
    controller.delegate = self
  }
  
  // MARK: UITextFieldDelegate Methods
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    
    let currentCharacterCount = textField.text?.characters.count ?? 0
    
    if (range.length + range.location > currentCharacterCount){
      return false
    }
    let newLength = currentCharacterCount + string.characters.count - range.length
    
    if (textField.tag == 1000) {
      return newLength <= 20 // Character Limit for Luggage Name
    } else {
      return newLength <= 12 // Character Limit for Identifier Code
    }
  }
  
  // MARK: Action Methods
  @IBAction func saveBeacon() {
    nameTextField.resignFirstResponder()
    uuidTextField.resignFirstResponder()
    
    trimmedName = nameTextField.text!.trimmingCharacters(
      in: CharacterSet.whitespacesAndNewlines
    )
    
    // Check/Get Luggage's Name
    assignLuggageName()
    
    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
      if let luggageItem = beaconToEdit {
        
        let originalStringIndex = luggageItem.uuid.characters.index(luggageItem.uuid.endIndex, offsetBy: -12)
        let originalString = luggageItem.uuid.substring(from: originalStringIndex)
        
        if (isPhotoEdited || (trimmedName! != luggageItem.name) || (uuidTextField.text! != originalString)) {
          // Beacon is Edited
          
          if (luggageItem.isConnected) {
            // Stop Monitoring for this Beacon
            delegate?.stopMonitoring(didStopMonitoring: luggageItem)
          }
          
          if (isPhotoEdited) {
            luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          luggageItem.name = trimmedName!
          luggageItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercased())"
          luggageItem.minor = (uuidTextField.text! != originalString) ? "-1" : luggageItem.minor
          luggageItem.regionState = Constants.Proximity.Outside
          
          delegate?.beaconDetailViewController(self, didFinishEditingItem: luggageItem)
        } else {
          Globals.log("No Changes made in LuggageTag")
          dismiss(animated: true, completion: nil)
        }

      } else {

        //New Luggage
        let luggageItem = LuggageTag()
        
        if (isPhotoEdited) {
          luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
          luggageItem.photo = nil
        }
        
        luggageItem.name = trimmedName!
        luggageItem.uuid = "\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercased())"
        luggageItem.major = "0"
        luggageItem.minor = "-1"
        luggageItem.regionState = Constants.Proximity.Outside
        luggageItem.isConnected = false
        
        delegate?.beaconDetailViewController(self, didFinishAddingItem: luggageItem)
      }
    }
  }
  
  // MARK: ModalViewControllerDelegate
  func didFinishPickingMediaWithInfo(_ image: UIImage) {
    isPhotoEdited = true
    imgButton.setImage(image, for: UIControlState())
    imgButton.imageView?.contentMode = UIViewContentMode.center
  }
  
  // MARK: CBCentralManagerDelegate Methods
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    switch (central.state) {
    case .poweredOn:
      break
    case .poweredOff:
      if let luggageTag = beaconToEdit {
        luggageTag.regionState = Constants.Proximity.Outside
        rangeLabel.text = Constants.Range.OutOfRange
        delegate?.didBluetoothPoweredOff(didPowerOff: luggageTag)
      }
    default:
      break
    }
  }
  
  // MARK: NSNotificationCenter Functions
  func keyboardWillShow(_ sender: Notification) {
    self.view.frame.origin.y = -150
  }
  
  func keyboardWillHide(_ sender: Notification) {
    self.view.frame.origin.y = 0
  }
  
  func setEnterRegion(_ notification: Notification) {
    let region = (notification as NSNotification).userInfo!["region"] as! CLBeaconRegion
    if let luggageTag = beaconToEdit {
      let connected = luggageTag.isConnected
      if (region.identifier == luggageTag.name && region.proximityUUID.uuidString == luggageTag.uuid && connected) {
        rangeLabel.text = Constants.Range.InRange
      }
    }
  }
  
  func setExitRegion(_ notification: Notification) {
    let region = (notification as NSNotification).userInfo!["region"] as! CLBeaconRegion
    if let luggageTag = beaconToEdit {
      if (region.identifier == luggageTag.name && region.proximityUUID.uuidString == luggageTag.uuid) {
        rangeLabel.text = Constants.Range.OutOfRange
      }
    }
  }
  
  // MARK: Private Methods
  fileprivate func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.isTranslucent = true
  }
  
  fileprivate func showConfirmation(_ title: String, message: String) {
    let actions = [
      UIAlertAction(title: NSLocalizedString("exit", comment: ""), style: .cancel) { (action) in
        Globals.log("Exit Adding/Editing Luggage")
        self.dismiss(animated: true, completion: nil)
      },
      UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .default, handler: nil)
    ]
    
    Globals.showAlert(self, title: title, message: message, animated: true, completion: nil, actions: actions)
  }
  
  fileprivate func assignLuggageName() {
    if (trimmedName! == "") {
      var num = 0
      
      repeat {
        num = num + 1
        trimmedName! = "\(Constants.Default.LuggageName) \(num)"
      } while checkTagAvailability()
    }
    
  }
  
  fileprivate func validateLuggage() -> Bool {
    if (uuidTextField.text! == "") {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      
      return false
    }
     
    if (uuidTextField.text!.characters.count < 12 || !(uuidTextField.text!.isValidHexNumber())) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      
      return false
    }
    
    if (!checkIdentifierCodeAvailability()) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
      
      return false
    }
    
    if (checkTagAvailability()) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
      
      return false
    }

    return true
  }
  
  fileprivate func checkIdentifierCodeAvailability() -> Bool {
    for beacon in beaconReference! {
      if (beacon.uuid == ("\(Constants.UUID.Identifier)\(uuidTextField.text!.uppercased())")) {
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
  
  fileprivate func checkTagAvailability() -> Bool {
    
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
  
  deinit {
    // Remove all Observer from this Controller to save memory
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Inside), object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Outside), object: nil)
  }
}
