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

class ActivationOptionsController: UIViewController {

 weak var delegate: ActivationOptionsControllerDelegate?
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.activationOptionsControllerDidCancel(self)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
