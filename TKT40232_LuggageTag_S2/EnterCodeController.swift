//
//  EnterCodeController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class EnterCodeController: UIViewController, UITextFieldDelegate {
var hexString: String?
    @IBOutlet weak var codeTextField: CustomTextField!
    
    @IBAction func cancel(_ sender: Any) {
        
         NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CencelActivationScreen), object: nil, userInfo: nil)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(EnterCodeController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
        
      
        
    }

    @IBAction func nextButton(_ sender: Any) {
        let isValidLuggage = validateLuggage()
        
      
        
        if (isValidLuggage) {
            let aCode: String = codeTextField.text!.lowercased()
            
            var BTAddress:Int64 = 0
            var powIndex = 0
            
            for char in aCode.characters.reversed() {
                let characterString = "\(char)"
                
                if let asciiValue = Character(characterString).asciiValue {
                    BTAddress += Int64(asciiValue - 96) * Int64("\(pow(26, powIndex))")!
                    powIndex += 1
                }
            }
            
            hexString = String(BTAddress, radix: 16, uppercase: true)
            let actCode:[String: String] = ["aCode": aCode]
            if let hex = hexString {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: hex, userInfo: actCode)
            }
        }
        
    }
    
    func keyboardWillShow(_ sender: Notification) {
        self.view.frame.origin.y = -150
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
       
    }
    
    func keyboardWillHide(_ sender: Notification) {
        self.view.frame.origin.y = 0
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
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
    
    fileprivate func validateLuggage() -> Bool {
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
            Globals.log("exit_confirmation")
            return false
        }
        
        
        return true
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
    

    
    deinit {
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
      
    }


}
