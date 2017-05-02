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

var beacons: [LuggageTag]?

class PagerViewController: UIViewController {
    
    var activatioNCode: String = ""
    var TAG_NAME: String = ""
    var ActivationKey: String = ""
    var UUID: String = ""
    
    var beaconReference: [LuggageTag]?
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var containerView: UIView!
    
    weak var delegate: BeaconDetailViewControllerDelegate?
    var activation_Code: String?
    
    var pageViewControllerObject: WizardPagerViewController? {
        didSet {
            pageViewControllerObject?.pageViewdelegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let beaconss = beaconReference{
            beacons = beaconss
        }
        
        self.navigationController?.transparentNavigationBar()
        
        hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
        pageControl.addTarget(self, action: #selector(PagerViewController.didChangePageControlValue), for: .valueChanged)
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.TapToNextButton(_:)), name:NSNotification.Name(rawValue: Constants.Notification.Go_To_Next_Page), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.enter_code(_:)), name:NSNotification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.goBack(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CencelActivationScreen), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.onBackgroundLocationAccessEnabled(_:)), name: NSNotification.Name(rawValue: Constants.Notification.OnBackgroundAccessEnabled), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.assignNameToActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.AssignNameToActivatingKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.stopActivatingBeacon(_:)), name: NSNotification.Name(rawValue: Constants.Notification.StopActivatingKey), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.Send_Tag_Name(_:)), name:NSNotification.Name(rawValue: Constants.Notification.SEND_TAG_NAME), object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.goBack(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CancelPhotoView), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.activateLuggageItem(_:)), name: NSNotification.Name(rawValue: Constants.Notification.SEND_PHOTO), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.showNavigationItem(_:)), name:NSNotification.Name(rawValue: Constants.Notification.ShowCancel), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.qrCancel(_:)), name:NSNotification.Name(rawValue: Constants.Notification.cancelDisappear), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.enter_code_qr(_:)), name:NSNotification.Name(rawValue: Constants.Notification.NEXT_BUTTON_QR), object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(PagerViewController.sampleLuggageItem(_:)), name:NSNotification.Name(rawValue: Constants.Notification.Create_Sample_Item), object: nil);
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue:Constants.Notification.ShowCancel), object: nil)
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func goBack(_ sender: Notification){
        pageViewControllerObject?.scrollToLastViewController()
    }
    
    
    
    
    func TapToNextButton(_ sender: Notification){
        
        
        if let uuid =  sender.userInfo?[Constants.Key.ActivatedUUID] as? String {
            UUID =  uuid
        }
        
        if let activationKey =  sender.userInfo?[Constants.Key.ActivationKey] as? String {
            ActivationKey = activationKey
        }
        pageViewControllerObject?.scrollToNextViewController()
    }
    
    func Send_Tag_Name(_ sender: Notification){
        
        let sendr: String  = sender.object as! String
        TAG_NAME = sendr
        pageViewControllerObject?.scrollToNextViewController()
        
    }
    
    
    func activateLuggageItem(_ sender: Notification){
        let luggageItem = LuggageTag()
        let photo = sender.object
        if let pic = photo {
            luggageItem.photo = pic as? Data
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
    
    func sampleLuggageItem(_ sender: Notification){
         Globals.log("sampleLuggageItem")
        let luggageItem = LuggageTag()
        let photo = sender.object
        if let pic = photo {
            luggageItem.photo = pic as? Data
        }
        
        luggageItem.name = "Sample Bag Item"
        luggageItem.uuid = "C2265660-5EC1-4935-9BB3-A1CBD9143388"
        luggageItem.major = "0"
        luggageItem.minor = "-1"
        luggageItem.regionState = Constants.Proximity.Inside
        luggageItem.isConnected = true
        luggageItem.activation_code = "aaobyoiummc"
        luggageItem.activation_key = "92DF78126A00"
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
        let aCode: String = sender.object as! String
        self.activatioNCode = aCode
        
        guard let ActivationOption = sender.userInfo?[Constants.Key.ActivationOption] as? String else {
            
            return
        }
        self.createHex(aCode: aCode, ActivationOption:ActivationOption)
    }
    
    
    func createHex(aCode:String, ActivationOption:String){
        Globals.log("This is ACODE \(aCode)")
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
        
        Globals.log("HEXSTRING  \(hexString)")
        
        self.activation_Code = aCode
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.TransmitActivationKey), object: hexString, userInfo: nil)
        
        if ActivationOption == "ac" {
            pageViewControllerObject?.scrollToNextViewController()  //go to NEXT PAGE
        }else if ActivationOption == "qr" {
            pageViewControllerObject?.scrollToViewController(index: 2)// go to SHAKE PAGE
        }else if ActivationOption == "retry" {
            self.pageViewControllerObject?.scrollToViewController(index: self.pageControl.currentPage) // stay on CURENT PAGE
        }
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewControllerObject = segue.destination as? WizardPagerViewController {
            self.pageViewControllerObject = pageViewControllerObject
        }
    }
    
    func didTapNextButton(_ sender: UIButton) {
        pageViewControllerObject?.scrollToNextViewController()
    }
    
    /**
     Fired when the user taps on the pageControl to change its current page.
     */
    func didChangePageControlValue() {
        pageViewControllerObject?.scrollToViewController(index: pageControl.currentPage)
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
                
                self.pageViewControllerObject?.scrollToViewController(index: 0)
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
        Globals.log("assignNameToActivatingBeacon")
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
        self.navigationController?.navigationBar.isTranslucent = true
        let shw = self.navigationItem.rightBarButtonItem
        shw?.isEnabled = true
        shw?.tintColor = UIColor.white
        //view.backgroundColor = UIColor.black.withAlphaComponent(0)
    }
    
    deinit {
        
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
    
    func pageViewControllerObject(_ pageViewControllerObject: WizardPagerViewController,
                                  didUpdatePageCount count: Int) {
        pageControl.numberOfPages = count
    }
    
    func pageViewControllerObject(_ pageViewControllerObject: WizardPagerViewController,
                                  didUpdatePageIndex index: Int) {
        pageControl.currentPage = index
    }
}

