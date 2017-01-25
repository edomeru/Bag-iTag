//
//  ModalViewController.swift
//  TKT40214_LuggageFinder_S1_iOS
//
//  Created by PhTktimac1 on 05/06/2016.
//  Copyright © 2016 Tektos Limited. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

extension UIButton{
  func roundCorners(_ corners:UIRectCorner, radius: CGFloat) {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.cgPath
    self.layer.mask = mask
  }
}

protocol ModalViewControllerDelegate: NSObjectProtocol {
  func didFinishPickingMediaWithInfo(_ image: UIImage)
}

class ModalViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var dimBackground: UIView!
  @IBOutlet weak var takePhotoButton: UIButton!
  @IBOutlet weak var choosePhotoButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  
  weak var delegate: ModalViewControllerDelegate?
  
  var isFromTakingPhoto: Bool = false
  
  override func viewDidLayoutSubviews() {
    takePhotoButton.roundCorners([.topLeft, .topRight], radius: 15.0)
    choosePhotoButton.roundCorners([.bottomLeft, .bottomRight], radius: 15.0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let gesture = UITapGestureRecognizer(target: self, action: #selector(ModalViewController.dismissModal))
    self.view.addGestureRecognizer(gesture)
  }
  
  func cameraPicker() {
    isFromTakingPhoto = true
    let cameraPicker = UIImagePickerController()
    cameraPicker.delegate = self
    cameraPicker.sourceType = .camera
    
    self.present(cameraPicker, animated: true, completion: nil)
  }
  
  func photoPicker() {
    isFromTakingPhoto = false
    let photoPicker = UIImagePickerController()
    photoPicker.delegate = self
    photoPicker.sourceType = .photoLibrary
    
    self.present(photoPicker, animated: true, completion: nil)
  }
  
  func showAlertforSettings(_ message: String) {
    let action = [
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .default) { (action) in
        if let url = URL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.shared.openURL(url)
        }
      },
      UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("error", comment: ""), message: message, animated: true, completion: nil, actions: action)
  }

  @IBAction func takePhoto(_ sender: AnyObject) {
    // Check if we have permission taking Camera
    if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) == AVAuthorizationStatus.authorized {
      // Already Authorized
      self.cameraPicker()
    } else {
      AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
        if granted {
          self.cameraPicker()
          
          return
        }
      })
      
      showAlertforSettings(NSLocalizedString("camera_restricted", comment: ""))
    }
  }
  
  @IBAction func choosePhoto(_ sender: AnyObject) {
    let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    
    switch status {
    case .authorized:
      photoPicker()
    case .denied:
      showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
    case .notDetermined:
      // Access has not been determined.
      PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) -> Void in
        if status == .authorized {
          self.photoPicker()
        }
        else {
          self.showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
        }
      })
    case .restricted:
      // Restricted access - normally won't happen.
      showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
    }
  }
  
  @IBAction func cancelClicked(_ sender: AnyObject) {
    dismiss(animated: false, completion: nil)
  }
  
  func dismissModal() {
    dismiss(animated: false, completion: nil)
  }
  
  //MARK: UIImagePickerControllerDelegate
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    let size = CGSize(width: 500, height: 500)
    let image = resizeImage((info[UIImagePickerControllerOriginalImage] as? UIImage)!, targetSize: size)
    Globals.log(isFromTakingPhoto)
    if (isFromTakingPhoto) {
      //Save to PhotosAlbum
      UIImageWriteToSavedPhotosAlbum((info[UIImagePickerControllerOriginalImage] as? UIImage)!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    delegate?.didFinishPickingMediaWithInfo(image)
    
    self.dismiss(animated: false, completion: nil)
    cancelButton.sendActions(for: .touchUpInside)
  }
  
  func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
      newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
      newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage!
  }
  
  func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let _ = error {
      // we got back an error!
      Globals.log("Error Saving Photo in Photo Album")
    } else {
      Globals.log("Success Saving Photo in Photo Album")
    }
  }

}
