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
    
    @IBOutlet weak var uuidTextField: CustomTextField!
    @IBAction func activate(_ sender: Any) {
    
        func viewWillAppear(animated: Bool) {
            super.viewWillAppear(animated)
           uuidTextField.becomeFirstResponder()
           
        }
      
        
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
    
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func keyboardWillShow(_ sender: Notification) {
        self.view.frame.origin.y = -150
    }
    
    func keyboardWillHide(_ sender: Notification) {
        self.view.frame.origin.y = 0
    }

}
