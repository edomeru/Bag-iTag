//
//  BeaconDetailViewController.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 26/05/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit
import CoreLocation

protocol BeaconDetailViewControllerDelegate: NSObjectProtocol {
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishAddingItem item: BeaconModel)
  func beaconDetailViewController(controller: BeaconDetailViewController, didFinishEditingItem item: BeaconModel)
  func deleteBeacon(didDeleteItem item: BeaconModel)
}

class BeaconDetailViewController: UIViewController, UITextFieldDelegate, TKTCoreLocationDelegate, ModalViewControllerDelegate {

  @IBOutlet weak var nameTextField: UITextField!
  @IBOutlet weak var uuidTextField: UITextField!
  @IBOutlet weak var button: UIButton!
  @IBOutlet weak var imgButton: UIButton!
  @IBOutlet weak var rangeLabel: UILabel!
  
  var tktCoreLocation: TKTCoreLocation!
  
  weak var delegate: BeaconDetailViewControllerDelegate?
  
  var beaconReference: [BeaconModel]?
  
  var beaconToEdit: BeaconModel?
  
  var isPhotoEdited = false
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    formatNavigationBar()
    
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil);
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BeaconDetailViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil);
    
    tktCoreLocation = TKTCoreLocation(delegate: self)
    
    if let item = beaconToEdit {
      if (item.photo != nil) {
        imgButton.setImage(UIImage(data: item.photo!), forState: .Normal)
      }
      
      if (item.proximity == "Inside") {
        rangeLabel.text = "In Range"
      } else {
        rangeLabel.text = "Not in Range"
      }
      
      nameTextField.text = item.name
      
      let stringIndex = item.UUID.endIndex.advancedBy(-12)
      uuidTextField.text = item.UUID.substringFromIndex(stringIndex)
    } else {
      rangeLabel.hidden = true
      button.setTitle("Cancel", forState: .Normal)
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
  
  // MARK: Action Methods
  @IBAction func saveBeacon() {
    
    nameTextField.resignFirstResponder()
    uuidTextField.resignFirstResponder()
    
    
    if (nameTextField.text! != "" && uuidTextField.text! != "") {
      // Check whether the beaconToEdit property contains an object
      // If True then it is a Edit else it is a new Beacon
      if let beaconItem = beaconToEdit {
        let originalStringIndex = beaconItem.UUID.endIndex.advancedBy(-12)
        let originalString = beaconItem.UUID.substringFromIndex(originalStringIndex)
        
        if (isPhotoEdited || (nameTextField.text! != beaconItem.name) || (uuidTextField.text! != originalString)) {
          // Beacon is Edited
          if (isPhotoEdited) {
            beaconItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
          }
          
          beaconItem.name = nameTextField.text!
          
          if uuidTextField.text!.characters.count == 12 {
            beaconItem.UUID = "C2265660-5EC1-4935-9BB3-\(uuidTextField.text!)"
          } else {
            beaconItem.UUID = uuidTextField.text!
          }
          
          delegate?.beaconDetailViewController(self, didFinishEditingItem: beaconItem)
          
          //MARK: TODO
        } else {
          print("NO Changes made in Beacon")
          dismissViewControllerAnimated(true, completion: nil)
        }
        
      } else {
        // New Beacon
        let beaconItem = BeaconModel()
       
        if (isPhotoEdited) {
          beaconItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
          beaconItem.photo = nil
        }
        
        if uuidTextField.text!.characters.count == 12 {
          beaconItem.UUID = "C2265660-5EC1-4935-9BB3-\(uuidTextField.text!)"
        } else {
          beaconItem.UUID = uuidTextField.text!
        }

        beaconItem.name = nameTextField.text!
        beaconItem.major = "1"
        beaconItem.minor = "5"
        beaconItem.isConnected = false
        
        delegate?.beaconDetailViewController(self, didFinishAddingItem: beaconItem)
        
        /*let isAvailable = checkBeaconAvailability()
        
        if (isAvailable) {
          delegate?.beaconDetailViewController(self, didFinishAddingItem: beaconItem)
        } else {
          showAlert()
        }*/
      }
    } else {
      print("NO beacon is Saved, because fields are empty")
      dismissViewControllerAnimated(true, completion: nil)
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
  }
  
  // MARK: Private Methods
  private func formatNavigationBar() {
    self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    self.navigationController?.navigationBar.shadowImage = UIImage()
    self.navigationController?.navigationBar.translucent = true
  }
  
  // MARK: TKTCoreLocationDelegate
  func onBackgroundLocationAccessDisabled() {}
  
  func didStartMonitoring() {}
  
  func didStopMonitoring() {}
  
  func didEnterRegion(region: CLRegion!) {
    if (region.identifier == beaconToEdit!.name) {
      beaconToEdit?.proximity = "Inside"
      rangeLabel.text = "In Range"
    }
  }
  
  func didExitRegion(region: CLRegion!) {
    if (region.identifier == beaconToEdit!.name) {
      beaconToEdit?.proximity = "Outside"
      rangeLabel.text = "Not in Range"
    }
  }
  
  func didRangeBeacon(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {}
  
  func keyboardWillShow(sender: NSNotification) {
    self.view.frame.origin.y = -150
  }
  
  func keyboardWillHide(sender: NSNotification) {
    self.view.frame.origin.y = 0
  }
  
  private func showAlert() {
    let alertController = UIAlertController(title: "Bag iTag", message: "This Beacon already Exist!", preferredStyle: .Alert)
    
    let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alertController.addAction(okAction)
    
    self.presentViewController(alertController, animated: true, completion: nil)
  }

  func checkBeaconAvailability() -> Bool {
    for beacon in beaconReference! {
      /*if (beacon.name == nameTextField.text! && beacon.UUID == uuidTextField.text!) {
        return false
      }
      else {
        return true
      }*/
      print(beacon.name)
    }
    
    return true
  }
  
  
}
