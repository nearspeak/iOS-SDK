//
//  DiscoveryTableViewController.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 23.04.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import UIKit
import NearspeakKit

class DiscoveryTableViewController: UITableViewController {
    
    var nearbyTags = [NSKTag]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Discovery"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNotifications()
        
        // true: show all beacons, also if the beacon has not data set on the server
        NSKManager.sharedInstance.startBeaconDiscovery(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSKManager.sharedInstance.stopBeaconDiscovery()
        
        removeNotifications()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // get notifications for if beacons updates appear
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onNearbyTagsUpdatedNotification:",
            name: NSKConstants.managerNotificationNearbyTagsUpdatedKey,
            object: nil)
        
        // get notification if bluetooth state changes
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onBluetoothErrorNotification:",
            name: NSKConstants.managerNotificationBluetoothErrorKey,
            object: nil)
        
        // get notifications if location state changes
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onLocationErrorNotification:",
            name: NSKConstants.managerNotificationLocationErrorKey,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onLocationOnlyWhenInUseNotification:",
            name: NSKConstants.managerNotificationLocationWhenInUseOnKey,
            object: nil)
    }
    
    private func removeNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(NSKConstants.managerNotificationNearbyTagsUpdatedKey)
    }
    
    func onNearbyTagsUpdatedNotification(notification: NSNotification) {
        // refresh the table view
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            // copy the nearbyTags from the shared instance
            self.nearbyTags = NSKManager.sharedInstance.nearbyTags
            self.tableView.reloadData()
        })
    }
    
    func onBluetoothErrorNotification(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alertController = UIAlertController(title: "Bluetooth Error", message: "Turn on bluetooth", preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    func onLocationErrorNotification(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alertController = UIAlertController(title: "Location Error", message: "Turn on location for this app.", preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    func onLocationOnlyWhenInUseNotification(notification: NSNotification) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alertController = UIAlertController(title: "Location Error", message: "Background scanning disabled.", preferredStyle: .Alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
            
            self.presentViewController(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyTags.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tagCell", forIndexPath: indexPath) 
        
        // get the current NSKTag item
        let tag = nearbyTags[indexPath.row]
        
        cell.textLabel?.text = tag.titleString()
        
        return cell
    }
}
