//
//  ShakeBeaconController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 21/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

protocol ShakeBeaconControllerDelegate: class {
    
    func shakeBeaconDidCancel(_ controller: ShakeBeaconController)
    
}



class ShakeBeaconController: UIViewController {

     weak var delegate: ShakeBeaconControllerDelegate?
    
    @IBAction func back(_ sender: Any) {
        delegate?.shakeBeaconDidCancel(self)
        
    }
    @IBOutlet weak var Back: UIBarButtonItem!
   

    override func viewDidLoad() {
        super.viewDidLoad()
 
       
    }



}
