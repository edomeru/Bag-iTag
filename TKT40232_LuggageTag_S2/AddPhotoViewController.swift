//
//  AddPhotoViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

protocol AddPhotoViewControllerDelegate: class {
    
    func addPhotoControllerDidCancel(_ controller: AddPhotoViewController)
    
}

class AddPhotoViewController: UIViewController, ModalViewControllerDelegate {
    
    @IBOutlet weak var nextSkipButton: CustomButton!
    weak var delegate: AddPhotoViewControllerDelegate?
    var photo: Data?
    var qrCodeFrameView:UIView?
    
    
    @IBOutlet weak var imgButton: CustomButton!
    var isPhotoEdited = false
    
    
    @IBAction func previous(_ sender: Any) {
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.CancelPhotoView), object: nil, userInfo: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func nextSkip(_ sender: Any) {
        if (isPhotoEdited) {
            photo = UIImageJPEGRepresentation(self.imgButton.currentImage!, 1.0)
        } else {
            photo = nil
        }
        
        if let bTState =  bluetoothState {
            if  bTState == false {

                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.showBluetoothWarning), object: nil, userInfo: nil)
            } else {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.Notification.SEND_PHOTO), object: photo, userInfo: nil)
            }
            
        }
    }
    
    
    // MARK: ModalViewControllerDelegate
    func didFinishPickingMediaWithInfo(_ image: UIImage) {
        isPhotoEdited = true
        imgButton.setImage(image, for: UIControlState())
        imgButton.imageView?.contentMode = UIViewContentMode.center
        nextSkipButton.setTitle("NEXT",for: .normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! ModalViewController
        controller.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}




