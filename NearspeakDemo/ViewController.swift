//
//  ViewController.swift
//  NearspeakDemo
//
//  Created by Patrick Steiner on 23.04.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import UIKit
import NearspeakKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var api = NSKApi(devMode: false)
        
        api.getAuthToken(username: "demo@appaya.at", password: "dasistnearspeak") { (succeeded, auth_token) -> () in
            if succeeded {
                var alertController = UIAlertController(title: "Auth-Token", message: "Your auth-token: \(auth_token)", preferredStyle: UIAlertControllerStyle.Alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                var alertController = UIAlertController(title: "ERROR", message: "Error while requesting the auth_token", preferredStyle: UIAlertControllerStyle.Alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

