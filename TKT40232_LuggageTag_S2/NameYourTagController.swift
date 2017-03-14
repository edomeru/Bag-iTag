//
//  NameYourTagController.swift
//  TKT40232_LuggageTag_S2
//
//  Created by Edmer Alarte on 13/3/2017.
//  Copyright © 2017 Tektos Limited. All rights reserved.
//

import UIKit

class NameYourTagController: UIViewController, AddPhotoControllerDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()

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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Segue.AddPhoto {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! AddPhotoController
            controller.delegate = self
            
           
        }
    }

    
    func addPhotoControllerDidCancel(_ controller: AddPhotoController) {
        dismiss(animated: true, completion: nil)
    }


}
