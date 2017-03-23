//
//  ChooseViewController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 22/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class ChooseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

       
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
}
