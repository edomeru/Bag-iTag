//
//  EnterCodeViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class EnterCodeViewController: UIViewController, UITextFieldDelegate {
  var hexString: String?
  @IBOutlet weak var codeTextField: CustomTextField!
  @IBOutlet weak var cancelOutlet: CustomButton!
  @IBOutlet weak var textLabel: UILabel!
  
  @IBOutlet weak var enterLabelTopSpaceConstraint: NSLayoutConstraint!
  @IBOutlet weak var nextBottomSpaceConstraints: NSLayoutConstraint!
  @IBOutlet weak var CancelBottomSpace: KeyboardLayoutConstraint!
  @IBOutlet weak var nextOutlet: CustomButton!
  @IBAction func cancel(_ sender: Any) {
    
    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CencelActivationScreen), object: nil, userInfo: nil)
    
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    
    Globals.log(" SCREEN HEIGHT 2   \(screenHeight())")
    
    codeTextField.autocapitalizationType = .allCharacters
    
    
    codeTextField.delegate = self
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    
    //codeTextField.addTarget(self, action: #selector(EnterCodeViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
    
    
    
  }
  
  func screenHeight() -> CGFloat {
    return UIScreen.main.bounds.height;
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    //NotificationCenter.default.removeObserver(self)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    codeTextField.text = ""
  }
  
  @IBAction func nextButton(_ sender: Any) {
    
    checkActivationCode()
    //        if let bTState =  bluetoothState {
    //            Globals.log(" bTState \(bTState)")
    //            if  bTState == false {
    //
    //                Globals.log("showBluetoothState")
    //                NotificationCenter.default.post(name: Notification.Name(rawValue: "didShowBluetoothState"), object: nil, userInfo: nil)
    //
    //            }
    //        }
  }
  
  func checkActivationCode(){
    
    
    let isValidLuggage = validateLuggage()
    
    if (isValidLuggage) {
      let aCode: String = codeTextField.text!.lowercased()
      let myDict: [String: Any] = [ Constants.Key.ActivationOption: "ac"]
      
      NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: aCode, userInfo: myDict)
    }
    
  }
  
  func textFieldDidChange(_ textField: UITextField) {
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    codeTextField.text = textField.text?.uppercased()
  }
  
  func keyboardWillShow(_ sender: Notification) {
    
    let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
    
    let systemVersion = UIDevice.current.systemVersion
    Globals.log("SYSTEM VERSION FLOAT  \(floatVersion)")
    Globals.log("SYSTEM VERSION   \(systemVersion)")
    
    //iOS version < 8.9
    if Double(floatVersion)  <= 8.9 {
      
      
      
      self.textLabel.frame.origin.y = -80
      
      Globals.log("textLabel.frame.origin.y  1 \(textLabel.frame.size.height)")
      
      /// iphone 4S screen
      if screenHeight() <= 490.0 {
        
        Globals.log("keyboardWillShow IF 1")
        
        //self.imageInputActivation.constant = 90
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        Globals.log("keyboardFrame 1\(keyboardHeight)")
        self.CancelBottomSpace.constant = keyboardHeight
        self.nextBottomSpaceConstraints.constant = keyboardHeight
        self.enterLabelTopSpaceConstraint.constant = screenHeight() - 450
        //                 self.codeTextField.frame.origin.y = screenHeight() - keyboardHeight
        //                self.cancelOutlet.frame.origin.y =  screenHeight() - keyboardHeight - 10
        //                self.nextOutlet.frame.origin.y =  self.view.frame.height - keyboardHeight  - 10
        
      }
      else{
        
        /// ! iphone 4S screen  && iOS version < 8.9
        Globals.log("keyboardWillShow   ELSE  1")
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.CancelBottomSpace.constant = keyboardHeight
        self.nextBottomSpaceConstraints.constant = keyboardHeight
        self.enterLabelTopSpaceConstraint.constant = self.view.frame.height - 500
        
        
      }
      
      
      
      
      
      
      //iOS version > 8.9
    }else{
      
      self.textLabel.frame.origin.y = 7
      self.codeTextField.frame.origin.y = 50
      Globals.log("keyboardWillShow")
      
      //iOS version > 8.9 && iPhone 4S
      if screenHeight() <= 490.0 {
        
        Globals.log("keyboardWillShow IF 2")
        
        //self.imageInputActivation.constant = 90
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        Globals.log("keyboardFrame \(keyboardHeight)")
        self.cancelOutlet.frame.origin.y =  self.view.frame.height - keyboardHeight - 45
        self.nextOutlet.frame.origin.y =  self.view.frame.height - keyboardHeight  - 45
        
      }else{
        //iOS version > 8.9 && ! iPhone 4S
        Globals.log("keyboardWillShow   ELSE 2")
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        
        self.cancelOutlet.frame.origin.y =  self.view.frame.height - keyboardHeight - 100
        self.nextOutlet.frame.origin.y =  self.view.frame.height - keyboardHeight - 100
      }
    }
  }
  
  func keyboardWillHide(_ sender: Notification) {
    
    let floatVersion = (UIDevice.current.systemVersion as NSString).floatValue
    
    let systemVersion = UIDevice.current.systemVersion
    
    Globals.log("SYSTEM VERSION   \(systemVersion)")
    
    
    if Double(floatVersion)  <= 8.9 {
      
      /// iOS 8
      
      self.textLabel.frame.origin.y = -80
      
      Globals.log("textLabel.frame.origin.y  \(textLabel.frame.size.height)")
      if screenHeight() <= 490.0 {
        
        Globals.log("keyboardWillShow IF")
        
        //self.imageInputActivation.constant = 90
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        Globals.log("keyboardFrame \(keyboardHeight)")
        self.CancelBottomSpace.constant = 27
        self.nextBottomSpaceConstraints.constant = 27
        self.enterLabelTopSpaceConstraint.constant = 126
        
        
      }else{
        Globals.log("keyboardWillShow   ELSE")
        let userInfo:NSDictionary = sender.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIKeyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        Globals.log("keyboardFrame \(keyboardHeight)")
        self.CancelBottomSpace.constant = 27
        self.nextBottomSpaceConstraints.constant = 27
        self.enterLabelTopSpaceConstraint.constant = 126
      }
      
      
      
      
      
      
      
    }else{
      //  > iOS 8
      self.view.frame.origin.y = 0
    }
    
    //        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
  }
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    
    return true
  }
  
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    
    // Do not let specified text range to be changed
    
    if string == "" {
      // User presses backspace
    } else {
      // User presses a key or pastes
      
      
      let currentCharacterCount = textField.text?.characters.count ?? 0
      
      if (range.length + range.location > currentCharacterCount){
        
        textField.insertText(string.uppercased())
        return false
      }
      let newLength = currentCharacterCount + string.characters.count - range.length
      
      if (textField.tag == 1000) {
        
        return newLength <= 11 // Character Limit for Luggage Name
      } else {
        
        Globals.log("string.uppercased()    \(string.uppercased())")
        textField.insertText(string.uppercased())
        
        return newLength <= 11 // Character Limit for Activation Code
      }
      
    }
    
    return true
    
  }
  
  
  fileprivate func validateLuggage() -> Bool {
    
    if let bTState =  bluetoothState {
      Globals.log(" bTState \(bTState)")
      if  bTState == false {
        
        Globals.log("showBluetoothState")
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.showBluetoothWarning), object: nil, userInfo: nil)
        return false
      }
      
    }
    
    
    if (codeTextField.text!.characters.count < 11) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("error_activation_code", comment: ""))
      Globals.log("error_activation_code")
      return false
    }
    
    if (codeTextField.text! == "") {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      Globals.log("exit_confirmation")
      return false
    }
    
    if (!(codeTextField.text!.isValidActivationCode())) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
      Globals.log("error_activation_code")
      return false
    }
    
    if (!checkActivationCodeAvailability()) {
      showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
      
      return false
    }
    
    return true
  }
  
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.view.endEditing(true)
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
  
  // TODO: Check Activation Code Uniqueness
  fileprivate func checkActivationCodeAvailability() -> Bool {
    Globals.log("checkActivationCodeAvailability ENTER \(beacons?.count)")
    for beacon in beacons! {
      Globals.log("Exit Adding/Editing Luggage")
      if (beacon.activation_code == codeTextField.text!.lowercased()) {
        Globals.log("Existing Activation code \(beacon.activation_code)")
        
        return false
      }
    }
    
    return true
  }
  
  @IBAction func floatingTextField(_ sender: Any) {
    
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
    NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    
  }
  
  deinit {
    
    //NotificationCenter.default.removeObserver(self)
    
  }
  
  
}
