//
//  ViewController.swift
//  NearspeakDemo
//
//  Created by Patrick Steiner on 23.04.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import UIKit
import NearspeakKit

class FetchViewController: UIViewController {

    @IBOutlet weak var tagIdentifierLabel: UITextField!
    @IBOutlet weak var fetchingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tagImageView: UIImageView!
    @IBOutlet weak var tagDescriptionLabel: UILabel!
    
    // Create a nearspeak api object
    fileprivate var api = NSKApi(devMode: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tagDescriptionLabel.text = ""
    }
    
    // MARK: - Testing
    
    fileprivate var authToken: String?
    
    fileprivate func login() {
        api.getAuthToken(username: "username", password: "password") { (succeeded, auth_token) -> () in
            if succeeded {
                self.authToken = auth_token
                
                self.addTag()
            }
        }
    }
    
    fileprivate func addTag() {
        let tag = NSKTag(id: -1)
        tag.translation = "Hello World"
        
        if api.isLoggedIn() {
            api.addTag(tag: tag, requestCompleted: { (succeeded, tag) -> () in
                if succeeded {
                    Log.debug("Tag successfully created")
                } else {
                    Log.error("Tag can't be created")
                }
            })
        } else {
            Log.error("Login first")
        }
    }
    
    // MARK - UI
    
    @IBAction func fetchButtonPushed(_ sender: AnyObject) {
        if !tagIdentifierLabel.text!.isEmpty {
            self.tagIdentifierLabel.resignFirstResponder()
            
            queryNearspeak(tagIdentifier: tagIdentifierLabel.text!)
        }
    }
    
    fileprivate func queryNearspeak(tagIdentifier: String) {
        fetchingActivityIndicator.startAnimating()
        
        // query for a nearspeak tag with a given tag identifier
        api.getTagById(tagIdentifier: tagIdentifier) { (succeeded, tag) -> () in
            if succeeded {
                if let tag = tag {
                    self.tagDescriptionLabel.text = tag.tagDescription
                    
                    if let imageURL = tag.imageURL {
                        self.tagImageView.image = self.fetchImageFromURL(imageURL)
                    }
                }
            } else {
                let alertController = UIAlertController(title: "ERROR", message: "Error while fetching tag", preferredStyle: .alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                self.present(alertController, animated: true, completion: nil)
            }
            
            self.fetchingActivityIndicator.stopAnimating()
        }
    }
    
    fileprivate func fetchImageFromURL(_ imageURL: URL) -> UIImage? {
        let imageData = try? Data(contentsOf: imageURL)
        
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        
        return nil
    }
}

