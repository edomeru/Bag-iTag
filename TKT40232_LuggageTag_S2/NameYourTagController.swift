//
//  NameYourTagController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class NameYourTagController: UIViewController, AddPhotoControllerDelegate, UITextFieldDelegate{
    
  
    var trimmedName:String?
   
    
    @IBOutlet weak var nameTextField: CustomTextField!
 
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
         nameTextField.delegate = self
        nameTextField.resignFirstResponder()
     
        Globals.log("Name Your Tag \(beaconLuggageReference)")
       
        
    }

 

 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.AddPhoto {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AddPhotoController
            controller.delegate = self
            
           
        }
    }

    
    func addPhotoControllerDidCancel(_ controller: AddPhotoController) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextButton(_ sender: Any) {
        
        
        trimmedName = nameTextField.text!
        trimmedName = nameTextField.text!.trimmingCharacters(
            in: CharacterSet.whitespacesAndNewlines
        )
        
        
       
        
        let isValidLuggage = validateLuggage()
        
        if (isValidLuggage) {
        
            if let Tag_name = trimmedName {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SEND_TAG_NAME), object: Tag_name, userInfo: nil)
            }
            
        
        }
    }

    fileprivate func validateLuggage() -> Bool {
//        if (nameTextField.text!.characters.count < 11) {
//            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("error_activation_code", comment: ""))
//            
//            return false
//        }
        
        if (nameTextField.text! == "") {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
            
            return false
        }
        
//        if (!(nameTextField.text!.isValidActivationCode())) {
//            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("exit_confirmation", comment: ""))
//            
//            return false
//        }
        
   
//        if (checkTagAvailability()) {
//            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
//            
//            return false
//        }
        
        return true
    }
    
    fileprivate func checkTagAvailability() -> Bool {
        
        for beacon in beaconLuggageReference! {
            if (beacon.name == trimmedName!) {
                
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
    
}
