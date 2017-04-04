//
//  PagerViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth
import Foundation

var beaconss: [LuggageTag]?

class PagerViewController: UIViewController , CLLocationManagerDelegate{
    
    var activatioNCode:String = ""
    var TAG_NAME:String = ""
    var ActivationKey:String = ""
    var UUID:String = ""
    
    var beaconReference: [LuggageTag]?
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
        
        if let beacons = beaconReference{
            beaconss = beacons
        }
        
        self.navigationController?.transparentNavigationBar()
        
        hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
        pageControl.addTarget(self, action: #selector(PagerViewController.didChangePageControlValue), for: .valueChanged)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapNextButton(_:)), name:NSNotification.Name(rawValue: Constants.Notification.INPUT_ACTIVATION_CODE), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.enter_code(_:)), name:NSNotification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.goBack(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CencelActivationScreen), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.onBackgroundLocationAccessEnabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.assignNameToActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.stopActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapToNextButton(_:)), name:NSNotification.Name(rawValue: Constants.Notification.ENTER_REGION), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.Send_Tag_Name(_:)), name:NSNotification.Name(rawValue: Constants.Notification.SEND_TAG_NAME), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.goBack(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CancelPhotoView), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapNextButton(_:)), name: NSNotification.Name(rawValue: Constants.Notification.TAKE_PHOTO), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.activateLuggageItem(_:)), name: NSNotification.Name(rawValue: Constants.Notification.SEND_PHOTO), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.showNavigationItem(_:)), name:NSNotification.Name(rawValue: Constants.Notification.ShowCancel), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.qrCancel(_:)), name:NSNotification.Name(rawValue: Constants.Notification.cancelDisappear), object: nil);
         NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.enter_code_qr(_:)), name:NSNotification.Name(rawValue: Constants.Notification.NEXT_BUTTON_QR), object: nil);
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Globals.log("viewWillDisappear in  PagerViewController")
         NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.ShowCancel), object: nil)
        NotificationCenter.default.removeObserver(self)
        
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
        guard let uuid = sender.userInfo?[Constants.Key.ActivatedUUID] as? String else {
            Globals.log("Invalid UUID Key from PageViewController")
            
            return
        }
        
        guard let aK = sender.userInfo?[Constants.Key.ActivationKey] as? String else {
            Globals.log("Invalid ActivationKey Key from PageViewController")
            
            return
        }
        
        guard let aC = sender.userInfo?[Constants.Key.ActivationCode] as? String else {
            Globals.log("Invalid ActivationCode Key from PageViewController")
            
            return
        }
        
        UUID =  uuid
        ActivationKey = aK
        
        tutorialPageViewController?.scrollToNextViewController()
        
    }
    
    func Send_Tag_Name(_ sender: Notification){
        
        let sendr: String  = sender.object as! String
        TAG_NAME = sendr
        tutorialPageViewController?.scrollToNextViewController()
        
    }
    
    
    func activateLuggageItem(_ sender: Notification){
        let luggageItem = LuggageTag()
        let PHOTO = sender.object
        if let pic = PHOTO {
            
            luggageItem.photo = PHOTO as! Data?
        }
        
        
        luggageItem.name = TAG_NAME
        luggageItem.uuid = UUID
        luggageItem.major = "0"
        luggageItem.minor = "-1"
        luggageItem.regionState = Constants.Proximity.Inside
        luggageItem.isConnected = true
        luggageItem.activation_code = activatioNCode.lowercased()
        luggageItem.activation_key = ActivationKey
        luggageItem.activated = true
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SavingNewLugguageItem), object: luggageItem, userInfo: nil)
    }
    
    
    func enter_code(_ sender: Notification){
        
        let aCode: String = sender.object as! String
        self.activatioNCode = aCode
        
        guard let ActivationOption = sender.userInfo?[Constants.Key.ActivationOption] as? String else {
            
            return
        }
        
        self.createHex(aCode: aCode, ActivationOption:ActivationOption)
        
    }
    
    func enter_code_qr(_ sender: Notification){
        Globals.log("Inside enter_code_qr")
        let aCode: String = sender.object as! String
        self.activatioNCode = aCode
        
        guard let ActivationOption = sender.userInfo?[Constants.Key.ActivationOption] as? String else {
            
            return
        }
         Globals.log("Abouve createHex  \(aCode) \(ActivationOption)")
        self.createHex(aCode: aCode, ActivationOption:ActivationOption)
        
    }
    
    func createHex(aCode:String, ActivationOption:String){
        
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
        self.activation_Code = aCode
        
        Globals.log("createHex")
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.TransmitActivationKey), object: hexString, userInfo: nil)
        
        if ActivationOption == "ac" {
            Globals.log("INSIDE AC")
            tutorialPageViewController?.scrollToNextViewController()  //go to NEXT PAGE
        }else if ActivationOption == "qr" {
            Globals.log("INSIDE QR")
            tutorialPageViewController?.scrollToViewController(index: 2)// go to SHAKE PAGE
        }else if ActivationOption == "retry" {
            Globals.log("INSIDE RETRY")
            self.tutorialPageViewController?.scrollToViewController(index: self.pageControl.currentPage) // stay on CURENT PAGE
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
        
        
        if timer.isValid {
            //timer.invalidate()
            showConfirmation(NSLocalizedString("Device activation failed", comment: ""), message: NSLocalizedString("", comment: ""))
        }
        
    }
    
    
    fileprivate func showConfirmation(_ title: String, message: String) {
        let actions = [
            UIAlertAction(title: NSLocalizedString("PREVIOUS", comment: ""), style: .cancel) { (action) in
                
                self.tutorialPageViewController?.scrollToViewController(index: 0)
            },
            UIAlertAction(title: NSLocalizedString("RETRY", comment: ""), style: .default){ (action) in
                
                self.createHex(aCode: self.activatioNCode,ActivationOption:"retry")
                
            }
        ]
        
        Globals.showAlert(self, title: title, message: message, animated: true, completion: nil, actions: actions)
    }
    
    func onBackgroundLocationAccessEnabled(_ notification: Notification) {
        
        if self.presentedViewController == nil {
            
            
            timer = Timer.scheduledTimer(timeInterval: Constants.Time.FifteenSecondsTimeout, target: self, selector: #selector(PagerViewController.callDismissShakeDeviceAlert), userInfo: nil, repeats: false)
            
        }
    }
    
    func assignNameToActivatingBeacon(_ notification: Notification) {
        Globals.log("assignNameToActivatingBeacon Called")
        guard let uuid = notification.userInfo?[Constants.Key.ActivatedUUID] as? String, let activationKey = notification.userInfo?[Constants.Key.ActivationKey] as? String else {
            Globals.log("Invalid UUID/Activation Key from TKTCoreLocation")
            
            return
        }
        
        
        
        let luggageItem = LuggageTag()
        
        
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
        delegate?.connectActivatingBeacon(item: luggageItem)
        
    }
    
    
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
    
    func showNavigationItem(_ notification: Notification) {
        
        let shw = self.navigationItem.rightBarButtonItem
        shw?.isEnabled = true
        shw?.tintColor = UIColor.white
       // view.backgroundColor = UIColor.clear
    }
    
    deinit {
        Globals.log("DE INIT PagerViewController")
        
         NotificationCenter.default.removeObserver(self)
        
        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.INPUT_ACTIVATION_CODE), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.NEXT_BUTTON), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.CallDismissShakeDeviceAlert), object: nil)
//        
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
//        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
    }
    
    
    
    
    @IBAction func qrCancel(_ sender: Any) {
        hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CancelQrScreen), object: nil, userInfo: nil)
    }
    fileprivate func formatNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.backgroundColor = .clear
        navigationController!.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.alpha = 0.0
    }
    
    fileprivate func hideNavigationItem(item: UIBarButtonItem?) {
        item?.isEnabled = false
        item?.tintColor = UIColor.clear
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

