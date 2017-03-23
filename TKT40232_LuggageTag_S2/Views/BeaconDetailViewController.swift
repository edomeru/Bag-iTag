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
import AVFoundation

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
  func connectActivatingBeacon(item: LuggageTag)
  func disconnectActivatingBeacon(item: LuggageTag)
  func didFinishActivatingBeacon(_ controller: BeaconDetailViewController, item: LuggageTag, isFromEdit: Bool)
}

class BeaconDetailViewController: UIViewController, CBCentralManagerDelegate, UITextFieldDelegate, ModalViewControllerDelegate, AVCaptureMetadataOutputObjectsDelegate {

  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var uuidTextField: UITextField!
  @IBOutlet weak var imgButton: UIButton!
  @IBOutlet weak var rangeLabel: UILabel!
  @IBOutlet weak var activationButton: CustomButton!
  @IBOutlet weak var qrCodeButton: UIButton!
  
  var centralManager: CBCentralManager!
  
  weak var delegate: BeaconDetailViewControllerDelegate?
  
  var beaconReference: [LuggageTag]?
  var beaconToEdit: LuggageTag?
  var isPhotoEdited = false
  var trimmedName: String?
  
  var captureSession:AVCaptureSession?
  var videoPreviewLayer:AVCaptureVideoPreviewLayer?
  var qrCodeFrameView:UIView?
  
  let supportedCodeTypes = [AVMetadataObjectTypeQRCode]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    formatNavigationBar()
    hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
    
    // NSNotification Observer for Keyboard
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    
    // NSNotification Observer for TKTCoreLocation in ListView
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.setEnterRegion(_:)), name: NSNotification.Name(rawValue: Constants.Proximity.Inside), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.setExitRegion(_:)), name: NSNotification.Name(rawValue: Constants.Proximity.Outside), object: nil)
//    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.onBackgroundLocationAccessEnabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
    
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.onBackgroundLocationAccessDisabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessDisabled), object: nil)
    
    // NSNotification Observer for Generating Name
//    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.assignNameToActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
    
    // NSNotification Observer for Stopping Activating Beacon
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.stopActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
    
    // NSNotification Observer for TransmitActivation Key
    NotificationCenter.default.addObserver(self, selector: #selector(BeaconDetailViewController.deviceIsActivated(_:)), name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
    centralManager = CBCentralManager(delegate: self, queue: nil)
    
    if let item = beaconToEdit {
      if (item.photo != nil) {
        imgButton.setImage(UIImage(data: item.photo! as Data), for: UIControlState())
        imgButton.imageView?.contentMode = UIViewContentMode.center
      }
      
      if (item.regionState == Constants.Proximity.Inside) {
        rangeLabel.text = Constants.Range.InRange
      } else {
        rangeLabel.text = Constants.Range.OutOfRange
      }
      
      nameTextField.text = item.name
      uuidTextField.text = beaconToEdit?.activation_code.uppercased()

      if (beaconToEdit?.activated)! {
        uuidTextField.isEnabled = false
        qrCodeButton.isHidden = true
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
          
          if (isPhotoEdited) {
            luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          let aCode = Globals.generateActivationCode(code: uuidTextField.text!.lowercased())
          let aKey = Globals.generateActivationKey(code: aCode)
          let uuid = Globals.generateUUID(code: aCode)
          
          luggageItem.name = trimmedName!
          luggageItem.uuid = uuid
          luggageItem.minor = (uuidTextField.text! != luggageItem.activation_code.uppercased()) ? "-1" : luggageItem.minor
          luggageItem.activation_code = uuidTextField.text!.lowercased()
          luggageItem.activation_key = aKey
          
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
  
    //TODO
  @IBAction func activate(_ sender: Any) {
    trimmedName = nameTextField.text!.trimmingCharacters(
      in: CharacterSet.whitespacesAndNewlines
    )
    
    // Check/Get Luggage's Name
    assignLuggageName()
    
    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
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
  
  @IBAction func qrButtonClicked(_ sender: Any) {
    hideNavigationItem(item: self.navigationItem.leftBarButtonItem)
    showNavigationItem(item: self.navigationItem.rightBarButtonItem)
    
    let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
    do {
      let input = try AVCaptureDeviceInput(device: captureDevice)
      captureSession = AVCaptureSession()
      captureSession?.addInput(input)
      
      let captureMetadataOutput = AVCaptureMetadataOutput()
      captureSession?.addOutput(captureMetadataOutput)
      
      // Set delegate and use the default dispatch queue to execute the call back
      captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
      
      // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
      videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer?.frame = view.layer.bounds
      view.layer.addSublayer(videoPreviewLayer!)
      
      // Start video capture.
      captureSession?.startRunning()
      
      // Initialize QR Code Frame to highlight the QR code
      qrCodeFrameView = UIView()
      
      if let qrCodeFrameView = qrCodeFrameView {
        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView)
        view.bringSubview(toFront: qrCodeFrameView)
      }
    } catch {
      Globals.log(error)
      
      return
    }
  }
  
  @IBAction func qrCancelButton(_ sender: Any) {
    hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
    showNavigationItem(item: self.navigationItem.leftBarButtonItem)
    
    captureSession?.stopRunning()
    qrCodeFrameView?.removeFromSuperview()
    videoPreviewLayer?.removeFromSuperlayer()
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
  
  // MARK: - AVCaptureMetadataOutputObjectsDelegate Methods
  func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if metadataObjects == nil || metadataObjects.count == 0 {
      qrCodeFrameView?.frame = CGRect.zero
      Globals.log("No QR/barcode is detected")
      
      return
    }
    
    // Get the metadata object.
    let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
    if supportedCodeTypes.contains(metadataObj.type) {
      // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
      let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
      qrCodeFrameView?.frame = barCodeObject!.bounds
      
      if let qrCode = metadataObj.stringValue {
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
          self.uuidTextField.text = qrCode
          self.hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
          self.showNavigationItem(item: self.navigationItem.leftBarButtonItem)
          self.self.captureSession?.stopRunning()
          self.qrCodeFrameView?.removeFromSuperview()
          self.videoPreviewLayer?.removeFromSuperlayer()
        }
      }
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
        
        if (uuidTextField.isEnabled && !qrCodeButton.isHidden && !activationButton.isHidden && rangeLabel.isHidden) {
          rangeLabel.isHidden = false
          uuidTextField.isEnabled = false
          qrCodeButton.isHidden = true
          activationButton.isHidden = true
        }
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
  
  func onBackgroundLocationAccessEnabled(_ notification: Notification) {

    Globals.log("onBackgroundLocationAccessEnabled_____")
    
    if self.presentedViewController == nil {
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
    }
  }
  
  func onBackgroundLocationAccessDisabled(_ notification: Notification) {
    let actions = [
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { (action) in
        if let url = URL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.shared.openURL(url)
        }
      },
      UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("location_access_disabled", comment: ""), message: NSLocalizedString("location_access_disabled_settings", comment: ""), animated: true, completion: nil, actions: actions)
  }
  
  func assignNameToActivatingBeacon(_ notification: Notification) {
    Globals.log("assignNameToActivatingBeacon Called")
    guard let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String, let activationKey = notification.userInfo?[Constants.Key.ActivationKey] as? String else {
      Globals.log("Invalid UUID/Activation Key from TKTCoreLocation")
      
      return
    }
    
    trimmedName = nameTextField.text!.trimmingCharacters(
      in: CharacterSet.whitespacesAndNewlines
    )
    
    // Check/Get Luggage's Name
    assignLuggageName()
    
    if let luggageItem = beaconToEdit {
      // Beacon is edited
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
      
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
      
      delegate?.connectActivatingBeacon(item: luggageItem)
    } else {
      // New Luggage
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
      NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
      
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

      delegate?.connectActivatingBeacon(item: luggageItem)
    }
  }
  
  func stopActivatingBeacon(_ notification: Notification) {
    guard let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String else {
      Globals.log("Invalid UUID Key from TKTCoreLocation")
      
      return
    }
    
    let luggageItem = LuggageTag()
    luggageItem.name = trimmedName!
    luggageItem.uuid = uuid
  
    delegate?.disconnectActivatingBeacon(item: luggageItem)
  }
  
  func deviceIsActivated(_ notification: Notification) {
    guard let _ = notification.userInfo?[Constants.Key.ActivationIdentifier] as? String, let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String, let activation_key = notification.userInfo?[Constants.Key.ActivationKey] as? String, let _ = notification.userInfo?[Constants.Key.ActivationCode] as? String else {
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
      
      if (isPhotoEdited) {
        luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
      }
      
      luggageItem.name = trimmedName!
      luggageItem.uuid = uuid
      luggageItem.minor = (uuidTextField.text! != luggageItem.activation_code.uppercased()) ? "-1" : luggageItem.minor
      luggageItem.regionState = Constants.Proximity.Inside
      luggageItem.isConnected = true
      luggageItem.activation_code = uuidTextField.text!.lowercased()
      luggageItem.activation_key = activation_key.uppercased()
      luggageItem.activated = true
      
      delegate?.didFinishActivatingBeacon(self, item: luggageItem, isFromEdit: true)
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
      luggageItem.activation_key = activation_key.uppercased()
      luggageItem.activated = true
      
      delegate?.didFinishActivatingBeacon(self, item: luggageItem, isFromEdit: false)
    }
  }
  
  // MARK: Private Methods
  fileprivate func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.isTranslucent = true
  }
  
  fileprivate func hideNavigationItem(item: UIBarButtonItem?) {
    item?.isEnabled = false
    item?.tintColor = UIColor.clear
  }
  
  fileprivate func showNavigationItem(item: UIBarButtonItem?) {
    item?.isEnabled = true
    item?.tintColor = UIColor.white
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
    
    if (!checkActivationCodeAvailability()) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
      
      return false
    }
    
    if (checkTagAvailability()) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
      
      return false
    }

    return true
  }
  
  // TODO: Check Activation Code Uniqueness
  fileprivate func checkActivationCodeAvailability() -> Bool {
    for beacon in beaconReference! {
      if (beacon.activation_code == uuidTextField.text!.lowercased()) {
        if let item = beaconToEdit {
          if (item.activation_code == beacon.activation_code) {
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
     Globals.log("DE INIT BEACON")
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Inside), object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Proximity.Outside), object: nil)
//    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessDisabled), object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.ActivationSuccessKey), object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
    
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
  }
}
