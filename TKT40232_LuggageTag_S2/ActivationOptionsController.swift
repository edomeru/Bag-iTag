//
//  ActivationOptionsController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

protocol ActivationOptionsControllerDelegate: class {
    
    func activationOptionsControllerDidCancel(_ controller: ActivationOptionsController)
   
}

class ActivationOptionsController: UIViewController, EnterActivationCodeControllerDelegate {

    weak var delegate: ActivationOptionsControllerDelegate?
    var beaconReference: [LuggageTag]?
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.activationOptionsControllerDidCancel(self)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
         Globals.log("ActivationOptionsController \(beaconReference!)")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.EnterActivationCode {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! EnterActivationCodeController
            controller.delegate = self
            Globals.log("ActivationOptionsController ONPREPARE \(beaconReference!)")
            controller.beaconRef = beaconReference
        }
    }
    
    func enterActivationCodeControllerDidCancel(_ controller: EnterActivationCodeController) {
        dismiss(animated: true, completion: nil)
    }

}
