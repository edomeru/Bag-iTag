//
//  AddPhotoController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

protocol AddPhotoControllerDelegate: class {
    
    func addPhotoControllerDidCancel(_ controller: AddPhotoController)
    
}

class AddPhotoController: UIViewController, ModalViewControllerDelegate {
    
weak var delegate: AddPhotoControllerDelegate?
  var photo:Data?
    var qrCodeFrameView:UIView?
    
    //let supportedCodeTypes = [AVMetadataObjectTypeQRCode]
    @IBOutlet weak var imgButton: CustomButton!
    @IBAction func previousButton(_ sender: Any) {
    }

    
 
        

        
        
 
    
    var isPhotoEdited = false
    @IBAction func previous(_ sender: Any) {
        
         NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CancelPhotoView), object: nil, userInfo: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
 self.navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }

   
    
    @IBAction func nextSkip(_ sender: Any) {
        if (isPhotoEdited) {
            photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
            photo = nil
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SEND_PHOTO), object: photo, userInfo: nil)
    }
    
    
    // MARK: ModalViewControllerDelegate
    func didFinishPickingMediaWithInfo(_ image: UIImage) {
        isPhotoEdited = true
        imgButton.setImage(image, for: UIControlState())
        imgButton.imageView?.contentMode = UIViewContentMode.center
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate Methods
//    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
//        
//        // Check if the metadataObjects array is not nil and it contains at least one object.
//        if metadataObjects == nil || metadataObjects.count == 0 {
//            qrCodeFrameView?.frame = CGRect.zero
//            Globals.log("No QR/barcode is detected")
//            
//            return
//        }
    
        // Get the metadata object.
//        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
//        if supportedCodeTypes.contains(metadataObj.type) {
//            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
//            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
//            qrCodeFrameView?.frame = barCodeObject!.bounds
//            
//            if let qrCode = metadataObj.stringValue {
//                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//                
//                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
//                    self.uuidTextField.text = qrCode
////                    self.hideNavigationItem(item: self.navigationItem.rightBarButtonItem)
////                    self.showNavigationItem(item: self.navigationItem.leftBarButtonItem)
//                    self.self.captureSession?.stopRunning()
//                    self.qrCodeFrameView?.removeFromSuperview()
//                    self.videoPreviewLayer?.removeFromSuperlayer()
//                }
//            }
//        }
//        
//    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! ModalViewController
        controller.delegate = self
    }
        
    
}




