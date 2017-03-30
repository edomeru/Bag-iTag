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
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    
    let supportedCodeTypes = [AVMetadataObjectTypeQRCode]
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        NotificationCenter.default.addObserver(self, selector: #selector(ChooseViewController.qrCancelButton(_:)), name: NSNotification.Name(rawValue: Constants.Notification.CancelQrScreen), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
       
    }
    

    @IBAction func inputActivationCode(_ sender: Any) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "INPUT_ACTIVATION_CODE"), object: nil, userInfo: nil)
        
    }

   
    
    @IBAction func cancel(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func qrButtonClicked(_ sender: Any) {
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
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
                    
                    Globals.log("QRCODE  \(qrCode.lowercased())")
                    //self.uuidTextField.text = qrCode
                    self.hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
                    //self.showNavigationItem(item: self.navigationItem.leftBarButtonItem)
                    self.self.captureSession?.stopRunning()
                    self.qrCodeFrameView?.removeFromSuperview()
                    self.videoPreviewLayer?.removeFromSuperlayer()
                    let myDict: [String: Any] = [ Constants.Key.ActivationOption: "qr"]
                     NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.NEXT_BUTTON), object: qrCode.lowercased(), userInfo: myDict)
                }
            }
        }
        
    }
    
    
//    func qrCancelButton(_ sender: Notification){
//        Globals.log("CancelQrScreen  ")
//        hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
//        showNavigationItem(item: self.navigationItem.leftBarButtonItem)
//        
//        captureSession?.stopRunning()
//        qrCodeFrameView?.removeFromSuperview()
//        videoPreviewLayer?.removeFromSuperlayer()
//
//    }
    
    @IBAction func qrCancelButton(_ sender: Any) {
                Globals.log("qrCancelButton  ")
                hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
                showNavigationItem(item: self.navigationItem.leftBarButtonItem)
        
                captureSession?.stopRunning()
                qrCodeFrameView?.removeFromSuperview()
                videoPreviewLayer?.removeFromSuperlayer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
