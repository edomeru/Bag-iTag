//
//  PagerViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit




class PagerViewController: UIViewController {
  
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var containerView: UIView!
    
  weak var delegate: BeaconDetailViewControllerDelegate?
    var activation_Code:String?
    
    var tutorialPageViewController: WizardPagerViewController? {
        didSet {
            tutorialPageViewController?.pageViewdelegate = self
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
           self.navigationController?.isNavigationBarHidden = true
        pageControl.addTarget(self, action: #selector(PagerViewController.didChangePageControlValue), for: .valueChanged)
        
     
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapNextButton(_:)), name:NSNotification.Name(rawValue: Constants.Notification.INPUT_ACTIVATION_CODE), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.enter_code(_:)), name:NSNotification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: nil);
        
//        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.callDismissShakeDeviceAlert(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CallDismissShakeDeviceAlert), object: nil)
        
          NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.goBack(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CencelActivationScreen), object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.onBackgroundLocationAccessEnabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.assignNameToActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
        
           NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.stopActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
        
         NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapToNextButton(_:)), name:NSNotification.Name(rawValue: Constants.Notification.ENTER_REGION), object: nil);
        
        
    }
    
    
    func goBack(_ sender: Notification){
        print("back")
        tutorialPageViewController?.scrollToLastViewController()
    }
    
    
    func TapNextButton(_ sender: Notification){
        
        tutorialPageViewController?.scrollToNextViewController()
        
         //NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.INPUT_ACTIVATION_CODE), object: nil)
    }
    
    func TapToNextButton(_ sender: Notification){
        
        tutorialPageViewController?.scrollToNextViewController()
        
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.INPUT_ACTIVATION_CODE), object: nil)
    }
    
    func enter_code(_ sender: Notification){
        if let hex = sender.object {
            print("HEXVALUE\(hex)")
            
            if let activationCode = sender.userInfo?["aCode"] as? String {
            
                self.activation_Code = activationCode
                 Globals.log("Activation_CODE\(activation_Code!)")
                    
                
            }
            
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.TransmitActivationKey), object: hex, userInfo: nil)
            
            tutorialPageViewController?.scrollToNextViewController()  //go to SHAKE PAGE
            
        }
    }
    
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if let tutorialPageViewController = segue.destination as? WizardPagerViewController {
                self.tutorialPageViewController = tutorialPageViewController
            }
        }
        
        func didTapNextButton(_ sender: UIButton) {
            tutorialPageViewController?.scrollToNextViewController()
        }
        
        /**
         Fired when the user taps on the pageControl to change its current page.
         */
        func didChangePageControlValue() {
            tutorialPageViewController?.scrollToViewController(index: pageControl.currentPage)
        }
    

    
    func callDismissShakeDeviceAlert(){
        print("callDismissShakeDeviceAlert")
//        let errorMessage = UIAlertController(title: NSLocalizedString("error", comment: ""), message: NSLocalizedString("error_activating_message", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
//        let okActionMotor = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: UIAlertActionStyle.default)
//        errorMessage.addAction(okActionMotor)
//        
//        self.present(errorMessage, animated: true, completion: nil)
       
          if timer.isValid {
         showConfirmation(NSLocalizedString("Device activation failed", comment: ""), message: NSLocalizedString("", comment: ""))
            }
        
        
    }
    
    
    fileprivate func showConfirmation(_ title: String, message: String) {
        let actions = [
            UIAlertAction(title: NSLocalizedString("PREVIOUS", comment: ""), style: .cancel) { (action) in
                
                self.tutorialPageViewController?.scrollToViewController(index: 0)
            },
            UIAlertAction(title: NSLocalizedString("RETRY", comment: ""), style: .default){ (action) in
                
                self.tutorialPageViewController?.scrollToViewController(index: self.pageControl.currentPage)
                
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: hex, userInfo: nil)
            }
        ]
        
        Globals.showAlert(self, title: title, message: message, animated: true, completion: nil, actions: actions)
    }
    
    func onBackgroundLocationAccessEnabled(_ notification: Notification) {
        
        Globals.log("onBackgroundLocationAccessEnabled_____PagerViewController")
        
        if self.presentedViewController == nil {
            //
            //            let alertShake = UIAlertController(title: NSLocalizedString("shake_device", comment: ""), message: NSLocalizedString("shake_device_message", comment: ""), preferredStyle: UIAlertControllerStyle.alert)
            //            self.present(alertShake, animated: true, completion: nil)
            
            
//            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Constants.Time.FifteenSecondsTimeout) {
          
          timer = Timer.scheduledTimer(timeInterval: Constants.Time.FifteenSecondsTimeout, target: self, selector: #selector(PagerViewController.callDismissShakeDeviceAlert), userInfo: nil, repeats: false)
            
            
                // alertShake.dismiss(animated: true, completion: nil)
                
                
//                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CallDismissShakeDeviceAlert), object: nil, userInfo: nil)
          
                
                  //self.callDismissShakeDeviceAlert()
              
                
          
                //self.callDismissShakeDeviceAlert()

               //NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
                
                
            //}
        }
    }

    func assignNameToActivatingBeacon(_ notification: Notification) {
        Globals.log("assignNameToActivatingBeacon Called")
        guard let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String, let activationKey = notification.userInfo?[Constants.Key.ActivationKey] as? String else {
            Globals.log("Invalid UUID/Activation Key from TKTCoreLocation")
            
            return
        }
        
//        trimmedName = nameTextField.text!.trimmingCharacters(
//            in: CharacterSet.whitespacesAndNewlines
//        )
        
        // Check/Get Luggage's Name
        //assignLuggageName()
        
//        if let luggageItem = beaconToEdit {
//            // Beacon is edited
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
//            
//            if (isPhotoEdited) {
//                luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
//            }
//            
//            luggageItem.name = trimmedName!
//            luggageItem.uuid = uuid
//            luggageItem.minor = (uuidTextField.text! != luggageItem.activation_code.uppercased()) ? "-1" : luggageItem.minor
//            luggageItem.regionState = Constants.Proximity.Inside
//            luggageItem.isConnected = true
//            luggageItem.activation_code = uuidTextField.text!.lowercased()
//            luggageItem.activation_key = activationKey.uppercased()
//            
//            delegate?.connectActivatingBeacon(item: luggageItem)
//        }else {
        
            
            // New Luggage
        
//            NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
        
            let luggageItem = LuggageTag()
            
//            if (isPhotoEdited) {
//                luggageItem.photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
//            } else {
//                luggageItem.photo = nil
//            }
        
            luggageItem.name = uuid
            luggageItem.uuid = uuid
            luggageItem.major = "0"
            luggageItem.minor = "-1"
            luggageItem.regionState = Constants.Proximity.Inside
            luggageItem.isConnected = true
        
        if let Acode = activation_Code {
            luggageItem.activation_code = Acode.lowercased()
             Globals.log("A_CODE \(Acode)")
        }
            luggageItem.activation_key = activationKey.uppercased()
             Globals.log("connectActivatingBeacon Called ACT KEY  \(activationKey.uppercased())")
        
         Globals.log("connectActivatingBeacon Called ACT KEY  \(luggageItem.uuid)")
        delegate?.connectActivatingBeacon(item: luggageItem)   ////TIGIL DITO
       
            //delegate?.connectActivatingBeaconItem(item: luggageItem)
        //}
        
       // NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
        
    }
    

//    override func viewWillDisappear(_ animated: Bool) {
//         super.viewWillDisappear(animated)
//        Globals.log("DE INIT viewWillDisappear")
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.INPUT_ACTIVATION_CODE), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.NEXT_BUTTON), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.CallDismissShakeDeviceAlert), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
//    }
    
    func stopActivatingBeacon(_ notification: Notification) {
        guard let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String else {
            Globals.log("Invalid UUID Key from TKTCoreLocation")
            
            return
        }
        
        let luggageItem = LuggageTag()
        luggageItem.name = uuid
        luggageItem.uuid = uuid
         Globals.log("stopActivatingBeacon")
        delegate?.disconnectActivatingBeacon(item: luggageItem)
    }
    
    
    deinit {
        Globals.log("DE INIT PagerViewController")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.INPUT_ACTIVATION_CODE), object: nil)
        
          NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.NEXT_BUTTON), object: nil)
        
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.CallDismissShakeDeviceAlert), object: nil)

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
    }
    
    
    }


extension PagerViewController: PageViewControllerDelegate {
    
    func tutorialPageViewController(_ tutorialPageViewController: WizardPagerViewController,
                                    didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    
    func tutorialPageViewController(_ tutorialPageViewController: WizardPagerViewController,
                                    didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
}

