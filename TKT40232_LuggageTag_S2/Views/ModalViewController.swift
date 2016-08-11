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
  func roundCorners(corners:UIRectCorner, radius: CGFloat) {
    let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
    let mask = CAShapeLayer()
    mask.path = path.CGPath
    self.layer.mask = mask
  }
}

protocol ModalViewControllerDelegate: NSObjectProtocol {
  func didFinishPickingMediaWithInfo(image: UIImage)
}

class ModalViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  @IBOutlet weak var dimBackground: UIView!
  @IBOutlet weak var takePhotoButton: UIButton!
  @IBOutlet weak var choosePhotoButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  
  weak var delegate: ModalViewControllerDelegate?
  
  override func viewDidLayoutSubviews() {
    takePhotoButton.roundCorners([.TopLeft, .TopRight], radius: 15.0)
    choosePhotoButton.roundCorners([.BottomLeft, .BottomRight], radius: 15.0)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    let gesture = UITapGestureRecognizer(target: self, action: #selector(ModalViewController.dismissModal))
    self.view.addGestureRecognizer(gesture)
  }
  
  func cameraPicker() {
    let cameraPicker = UIImagePickerController()
    cameraPicker.delegate = self
    cameraPicker.sourceType = .Camera
    
    self.presentViewController(cameraPicker, animated: true, completion: nil)
  }
  
  func photoPicker() {
    let photoPicker = UIImagePickerController()
    photoPicker.delegate = self
    photoPicker.sourceType = .PhotoLibrary
    
    self.presentViewController(photoPicker, animated: true, completion: nil)
  }
  
  func showAlertforSettings(message: String) {
    let action = [
      UIAlertAction(title: NSLocalizedString("settings", comment: ""), style: .Default) { (action) in
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
          UIApplication.sharedApplication().openURL(url)
        }
      },
      UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .Cancel, handler: nil)
    ]
    
    Globals.showAlert(self, title: NSLocalizedString("error", comment: ""), message: message, animated: true, completion: nil, actions: action)
  }

  @IBAction func takePhoto(sender: AnyObject) {
    // Check if we have permission taking Camera
    if AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) == AVAuthorizationStatus.Authorized {
      // Already Authorized
      self.cameraPicker()
    } else {
      AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (granted: Bool) -> Void in
        if granted {
          self.cameraPicker()
          
          return
        }
      })
      
      showAlertforSettings(NSLocalizedString("camera_restricted", comment: ""))
    }
  }
  
  @IBAction func choosePhoto(sender: AnyObject) {
    let status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
    
    switch status {
    case .Authorized:
      photoPicker()
    case .Denied:
      showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
    case .NotDetermined:
      // Access has not been determined.
      PHPhotoLibrary.requestAuthorization({(status: PHAuthorizationStatus) -> Void in
        if status == .Authorized {
          self.photoPicker()
        }
        else {
          self.showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
        }
      })
    case .Restricted:
      // Restricted access - normally won't happen.
      showAlertforSettings(NSLocalizedString("photo_restricted", comment: ""))
    }
  }
  
  @IBAction func cancelClicked(sender: AnyObject) {
    dismissViewControllerAnimated(false, completion: nil)
  }
  
  func dismissModal() {
    dismissViewControllerAnimated(false, completion: nil)
  }
  
  //MARK: UIImagePickerControllerDelegate
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    let size = CGSize(width: 500, height: 500)
    let image = resizeImage((info[UIImagePickerControllerOriginalImage] as? UIImage)!, targetSize: size)
    
    delegate?.didFinishPickingMediaWithInfo(image)
    
    self.dismissViewControllerAnimated(false, completion: nil)
    cancelButton.sendActionsForControlEvents(.TouchUpInside)
  }
  
  func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    
    let widthRatio  = targetSize.width  / image.size.width
    let heightRatio = targetSize.height / image.size.height
    
    // Figure out what our orientation is, and use that to form the rectangle
    var newSize: CGSize
    if(widthRatio > heightRatio) {
      newSize = CGSizeMake(size.width * heightRatio, size.height * heightRatio)
    } else {
      newSize = CGSizeMake(size.width * widthRatio,  size.height * widthRatio)
    }
    
    // This is the rect that we've calculated out and this is what is actually used below
    let rect = CGRectMake(0, 0, newSize.width, newSize.height)
    
    // Actually do the resizing to the rect using the ImageContext stuff
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.drawInRect(rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage
  }


}