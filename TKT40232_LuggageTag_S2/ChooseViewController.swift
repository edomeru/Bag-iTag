//
//  ChooseViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import Foundation
import AVFoundation



class ChooseViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    let supportedCodeTypes = [AVMetadataObjectTypeQRCode]
    var QRCODE: String?
    weak var delegate: TKTCoreLocationDelegate?
    @IBOutlet weak var cancelConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageInputActivation: NSLayoutConstraint!
    
    @IBOutlet weak var inputActivationButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var qrButtonConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageQrConstraint: NSLayoutConstraint!
    @IBOutlet weak var activationCodeOutlet: CustomButton!
    @IBOutlet weak var qrCodeOutlet: CustomButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        Globals.log(" SCREEN HEIGHT \(screenHeight())")
        Globals.log(" bluetoothState \(bluetoothState!)")
        
        
        if screenHeight() <= 490.0 {
            self.imageInputActivation.constant = 90
            self.imageQrConstraint.constant = 80
            self.qrButtonConstraint.constant = 42
            self.inputActivationButtonConstraint.constant  = 42
            self.cancelConstraint.constant  = 42
            
        }
        self.activationCodeOutlet.setTitle(NSLocalizedString("input_activation_code",comment: ""), for: .normal)
        
        self.qrCodeOutlet.setTitle(NSLocalizedString("scan_qr_code_to_activate",comment: ""), for: .normal)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChooseViewController.qrCancelButton(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CancelQrScreen), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        // NotificationCenter.default.removeObserver(self)
    }
    
    func screenHeight() -> CGFloat {
        return UIScreen.main.bounds.height;
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func inputActivationCode(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.Go_To_Next_Page), object: nil, userInfo: nil)
        
        if let bTState =  bluetoothState {
            Globals.log(" bTState \(bTState)")
            if  bTState == false {
                
                Globals.log("showBluetoothState")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.showBluetoothWarning), object: nil, userInfo: nil)
                
            }
        }
        
        
        
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func qrButtonClicked(_ sender: Any) {
        
        if let bTState =  bluetoothState {
            Globals.log(" bTState \(bTState)")
            if  bTState == false {
                
                Globals.log("showBluetoothState")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.showBluetoothWarning), object: nil, userInfo: nil)
               
            }
        }
        
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            // Set delegate and use the default dispatch queue to execute the call back
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            captureSession?.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = UIView()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                qrCodeFrameView.layer.borderWidth = 2
                view.addSubview(qrCodeFrameView)
                view.bringSubview(toFront: qrCodeFrameView)
                
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.ShowCancel), object: nil, userInfo: nil)
            }
        } catch {
            Globals.log(error)
            
            return
        }
        
    }
    
    // MARK: Private Methods
    fileprivate func formatNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    fileprivate func hideNavigationItem(item: UIBarButtonItem?) {
        item?.isEnabled = false
        item?.tintColor = UIColor.clear
    }
    
    func showNavigationItem(item: UIBarButtonItem?) {
        item?.isEnabled = true
        item?.tintColor = UIColor.white
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate Methods
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        Globals.log("captureOutput")
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            Globals.log("No QR/barcode is detected")
            
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        if supportedCodeTypes.contains(metadataObj.type) {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            qrCodeFrameView?.frame = barCodeObject!.bounds
            if let qrCode = metadataObj.stringValue {
                Globals.log("qrCodemetadataObj")
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                //                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                
                self.hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
                self.self.captureSession?.stopRunning()
                self.qrCodeFrameView?.removeFromSuperview()
                self.videoPreviewLayer?.removeFromSuperlayer()
                Globals.log("videoPreviewLayer")
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.cancelDisappear), object: nil, userInfo: nil)
                
                self.QRCODE = qrCode.lowercased()
                Globals.log("QR CODE LOWERCASE \(qrCode.lowercased())")
                let isValidLuggage = self.validateLuggage()
                
                if (isValidLuggage) {
                    self.hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
                    
                    let myDict: [String: Any] = [ Constants.Key.ActivationOption: "qr"]
                    Globals.log("qrCode.lowercased() \(qrCode.lowercased())")
                    
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.NEXT_BUTTON_QR), object: qrCode.lowercased(), userInfo: myDict)
                }
                //}
            }
        }
        
    }
    
    fileprivate func validateLuggage() -> Bool {
        
       
        
        if (!checkActivationCodeAvailability()) {
            showConfirmation(NSLocalizedString("warning", comment: ""), message: NSLocalizedString("err_luggage_exist", comment: ""))
            
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
    
    // TODO: Check Activation Code Uniqueness
    fileprivate func checkActivationCodeAvailability() -> Bool {
        Globals.log("checkActivationCodeAvailability \(beacons?.count)")
        
        for beacon in beacons! {
            Globals.log("CHECK QR VALIDATION  1 \(self.QRCODE)")
            if let qr =  QRCODE{
                Globals.log("CHECK QR VALIDATION 2  \(qr)")
                if (beacon.activation_code == qr ) {
                    
                    return false
                }
            }
            
        }
        
        return true
    }
    
    
    //    func showBluetoothState(){
    //        Globals.log("HELLLLLLOOOOO")
    //        NotificationCenter.default.post(name: Notification.Name(rawValue: "didShowBluetoothState"), object: nil, userInfo: nil)
    //
    //
    //    }
    
    @IBAction func qrCancelButton(_ sender: Any) {
        
        hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
        //showNavigationItem(item: self.navigationItem.leftBarButtonItem)
        captureSession?.stopRunning()
        qrCodeFrameView?.removeFromSuperview()
        videoPreviewLayer?.removeFromSuperlayer()
    }
    
    deinit {
        
        //NotificationCenter.default.removeObserver(self)
    }
    
    
    
}
