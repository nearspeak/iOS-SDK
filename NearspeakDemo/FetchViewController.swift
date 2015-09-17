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
    private var api = NSKApi(devMode: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tagDescriptionLabel.text = ""
    }
    
    @IBAction func fetchButtonPushed(sender: AnyObject) {
        if !tagIdentifierLabel.text!.isEmpty {
            self.tagIdentifierLabel.resignFirstResponder()
            
            queryNearspeak(tagIdentifier: tagIdentifierLabel.text!)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func queryNearspeak(tagIdentifier tagIdentifier: String) {
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
                let alertController = UIAlertController(title: "ERROR", message: "Error while fetching tag", preferredStyle: .Alert)
                
                alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
            self.fetchingActivityIndicator.stopAnimating()
        }
    }
    
    private func fetchImageFromURL(imageURL: NSURL) -> UIImage? {
        let imageData = NSData(contentsOfURL: imageURL)
        
        if let imageData = imageData {
            return UIImage(data: imageData)
        }
        
        return nil
    }
}

