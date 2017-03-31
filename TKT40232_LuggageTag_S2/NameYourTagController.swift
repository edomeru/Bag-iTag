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
    var placeholderName:String = ""
    var myMutableStringTitle = NSMutableAttributedString()
    @IBOutlet weak var nameTextField: CustomTextField!
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assignPlaceHolderName()
        nameTextField.delegate = self
        nameTextField.resignFirstResponder()
        
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
        
        assignLuggageName()
        
        let isValidLuggage = validateLuggage()
        
        if (isValidLuggage) {
            
            if let Tag_name = trimmedName {
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SEND_TAG_NAME), object: Tag_name, userInfo: nil)
            }
            
        }
    }

    fileprivate func validateLuggage() -> Bool {
        
        
        if (checkTagAvailability()) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
            
            return false
        }
        
        return true
    }
    
    fileprivate func checkTagAvailability() -> Bool {
        
        for beacon in beaconss! {
            
            if let trmName =  trimmedName{
                if (beacon.name == trmName) {

                    return true
                }
            }
        }
        return false
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
    
    
    fileprivate func assignPlaceHolderName() {
        
        var num = 0
        
        repeat {
            num = num + 1
            placeholderName = "\(Constants.Default.LuggageName) \(num)"
            
            
            var myMutableStringTitle = NSMutableAttributedString()
            
            
            myMutableStringTitle = NSMutableAttributedString(string:placeholderName) // Font
            myMutableStringTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.gray, range:NSRange(location:0,length:placeholderName.characters.count))    // Color
            nameTextField.attributedPlaceholder = myMutableStringTitle
            
        } while checkTagAvailabilityForPlaceholder()
        
        
    }
    
    fileprivate func checkTagAvailabilityForPlaceholder() -> Bool {
        
        
        for beacon in beaconss! {

            if (beacon.name == placeholderName) {
                
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
}
