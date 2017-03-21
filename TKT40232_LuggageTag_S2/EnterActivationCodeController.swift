//
//  EnterActivationCodeController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit



protocol EnterActivationCodeControllerDelegate: class {
    
    func enterActivationCodeControllerDidCancel(_ controller: EnterActivationCodeController)
    
}



class EnterActivationCodeController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: EnterActivationCodeControllerDelegate?
    var beaconToEdit: LuggageTag?
    var trimmedName: String?
    var beaconRef: [LuggageTag]?
    
    func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        uuidTextField.becomeFirstResponder()
        
    }
    
    @IBOutlet weak var uuidTextField: CustomTextField!
    
    
    ///  NEXT BUTTON
    @IBAction func activate(_ sender: Any) {
    
       
      
        
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
    
    fileprivate func validateLuggage() -> Bool {
        if (uuidTextField.text!.characters.count < 11) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("error_activation_code", comment: ""))
            Globals.log("error_activation_code")
            return false
        }
        
        if (uuidTextField.text! == "") {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
             Globals.log("exit_confirmation")
            return false
        }
        
        if (!(uuidTextField.text!.isValidActivationCode())) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
            Globals.log("exit_confirmation")
            return false
        }
        
        if (!checkActivationCodeAvailability()) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
            Globals.log("err_luggage_exist")
            return false
        }
        
        if (checkTagAvailability()) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
            Globals.log("err_luggage_exist")
            return false
        }
        
        return true
    }
    
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
    
    
    // TODO: Check Activation Code Uniqueness
    fileprivate func checkActivationCodeAvailability() -> Bool {
        for beacon in beaconRef! {
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
        
        for beacon in beaconRef! {
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
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
         Globals.log("ENTERACTIVATIONCODE \(beaconRef)")
        // Do any additional setup after loading the view.
        
        // NSNotification Observer for Keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(EnterActivationCodeController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(EnterActivationCodeController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(EnterActivationCodeController.onBackgroundLocationAccessEnabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)

    
        
    }


    func keyboardWillShow(_ sender: Notification) {
        self.view.frame.origin.y = -150
    }
    
    func keyboardWillHide(_ sender: Notification) {
        self.view.frame.origin.y = 0
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        <#code#>
    }

}
