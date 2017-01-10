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
  
  func isValidActivationCode() -> Bool {
    let chars = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz").inverted
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
  @IBOutlet weak var activationButton: CustomButton!
  
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
    
    // NSNotification Observer for TransmitActivation Key
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.deviceIsActivated(_:)), name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
    
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
      uuidTextField.text = beaconToEdit?.activation_code.uppercased()
      
      if (beaconToEdit?.activated)! {
        uuidTextField.isEnabled = false
        activationButton.isHidden = true
      } else {
        rangeLabel.isHidden = true
      }
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
      return newLength <= 11 // Character Limit for Activation Code
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
        
        if (isPhotoEdited || (trimmedName! != luggageItem.name) || (uuidTextField.text! != luggageItem.activation_code.uppercased())) {
          // Beacon is Edited
          
          if (luggageItem.isConnected) {
            // Stop Monitoring for this Beacon
            delegate?.stopMonitoring(didStopMonitoring: luggageItem)
          }
          
          if (isPhotoEdited) {
            luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          let aCode = Globals.generateActivationCode(code: uuidTextField.text!.lowercased())
          let aKey = Globals.generateActivationKey(code: aCode)
          let uuid = Globals.generateUUID(code: aCode)
          
          luggageItem.name = trimmedName!
          luggageItem.uuid = uuid
          luggageItem.minor = (uuidTextField.text! != luggageItem.activation_code.uppercased()) ? "-1" : luggageItem.minor
          luggageItem.regionState = Constants.Proximity.Outside
          luggageItem.activation_code = uuidTextField.text!.lowercased()
          luggageItem.activation_key = aKey
          luggageItem.activated = (beaconToEdit?.activated)!
          
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
        
        let aCode = Globals.generateActivationCode(code: uuidTextField.text!.lowercased())
        let aKey = Globals.generateActivationKey(code: aCode)
        let uuid = Globals.generateUUID(code: aCode)
        
        luggageItem.name = trimmedName!
        luggageItem.uuid = uuid
        luggageItem.major = "0"
        luggageItem.minor = "-1"
        luggageItem.regionState = Constants.Proximity.Outside
        luggageItem.isConnected = false
        luggageItem.activation_code = uuidTextField.text!.lowercased()
        luggageItem.activation_key = aKey
        luggageItem.activated = false
        
        delegate?.beaconDetailViewController(self, didFinishAddingItem: luggageItem)
      }
    }
  }
  
  @IBAction func activate(_ sender: Any) {
    trimmedName = nameTextField.text!.trimmingCharacters(
      in: CharacterSet.whitespacesAndNewlines
    )
    
    // Check/Get Luggage's Name
    assignLuggageName()
    
    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
      let alertShake = UIAlertController(title: NSLocalizedString("shake_device", comment: ""), message: NSLocalizedString("shake_device_message", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
      self.present(alertShake, animated: true, completion: nil)
      
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constants.Time.FifteenSecondsTimeout) {
        alertShake.dismiss(animated: true, completion: nil)
        self.trimmedName = ""
        
        let errorMessage = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("error_activating_message", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
        let okActionMotor = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: UIAlertActionStyle.default)
        errorMessage.addAction(okActionMotor)
        
        self.present(errorMessage, animated: true, completion: nil)
      }
      
      let aCode: String = uuidTextField.text!.lowercased()
      
      var BTAddress:Int64 = 0
      var powIndex = 0
      
      for char in aCode.characters.reversed() {
        let characterString = "\(char)"
        
        if let asciiValue = Character(characterString).asciiValue {
          BTAddress += Int64(asciiValue - 96) * Int64("\(pow(26, powIndex))")!
          powIndex += 1
        }
      }
      
      let hexString = String(BTAddress, radix: 16, uppercase: true)
      NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.TransmitActivationKey), object: hexString, userInfo: nil)
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
  
  func deviceIsActivated(_ notification: Notification) {
    guard let _ = notification.userInfo?[Constants.Key.ActivationCode] as? String, let activationKey = notification.userInfo?[Constants.Key.ActivationKey] as? String, let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String else {
      Globals.log("Invalid Activated Data")
      
      return
    }
    
    trimmedName = nameTextField.text!.trimmingCharacters(
      in: CharacterSet.whitespacesAndNewlines
    )
    
    // Check/Get Luggage's Name
    assignLuggageName()
    
    if let luggageItem = beaconToEdit {
      // Beacon is Edited
      // Remove ActivationSuccessKey Notification
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
      
      if (luggageItem.isConnected) {
        // Stop Monitoring for this Beacon
        delegate?.stopMonitoring(didStopMonitoring: luggageItem)
      }
      
      if (isPhotoEdited) {
        luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
      }
      
      luggageItem.name = trimmedName!
      luggageItem.uuid = uuid
      luggageItem.minor = (uuidTextField.text! != luggageItem.activation_code.uppercased()) ? "-1" : luggageItem.minor
      luggageItem.regionState = Constants.Proximity.Inside
      luggageItem.isConnected = true
      luggageItem.activation_code = uuidTextField.text!.lowercased()
      luggageItem.activation_key = activationKey.uppercased()
      luggageItem.activated = true
      
      delegate?.beaconDetailViewController(self, didFinishEditingItem: luggageItem)
    } else {
      //New Luggage
      // Remove ActivationSuccessKey Notification
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
      
      let luggageItem = LuggageTag()
      
      if (isPhotoEdited) {
        luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
      } else {
        luggageItem.photo = nil
      }
      
      luggageItem.name = trimmedName!
      luggageItem.uuid = uuid
      luggageItem.major = "0"
      luggageItem.minor = "-1"
      luggageItem.regionState = Constants.Proximity.Inside
      luggageItem.isConnected = true
      luggageItem.activation_code = uuidTextField.text!.lowercased()
      luggageItem.activation_key = activationKey.uppercased()
      luggageItem.activated = true
      
      delegate?.beaconDetailViewController(self, didFinishAddingItem: luggageItem)
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
    if (uuidTextField.text!.characters.count < 11) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("error_activation_code", comment: ""))
      
      return false
    }
    
    if (uuidTextField.text! == "") {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      
      return false
    }
    
    if (!(uuidTextField.text!.isValidActivationCode())) {
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
    //Globals.log("Deinit called")
    // Remove all Observer from this Controller to save memory
    //NotificationCenter.default.removeObserver(self)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Inside), object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Outside), object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
  }
}
