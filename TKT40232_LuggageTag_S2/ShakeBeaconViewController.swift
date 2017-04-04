//
//  ShakeBeaconViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 21/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

protocol ShakeBeaconViewControllerDelegate: class {
    
    func shakeBeaconDidCancel(_ controller: ShakeBeaconViewController)
    
}



class ShakeBeaconViewController: UIViewController {

     weak var delegate: ShakeBeaconViewControllerDelegate?
    
    @IBAction func back(_ sender: Any) {
        delegate?.shakeBeaconDidCancel(self)
        
    }
    @IBOutlet weak var Back: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

    }

}
