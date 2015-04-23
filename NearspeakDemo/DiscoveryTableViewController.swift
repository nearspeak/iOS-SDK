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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNotifications()
        
        // true: show all beacons, also if the beacon has not data set on the server
        NSKManager.sharedInstance.startBeaconDiscovery(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeNotifications()
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        // get notifications for if beacons updates appear
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onNearbyTagsUpdatedNotification:",
            name: NSKConstants.managerNotificationNearbyTagsUpdatedKey,
            object: nil)
    }
    
    private func removeNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(NSKConstants.managerNotificationNearbyTagsUpdatedKey)
    }
    
    func onNearbyTagsUpdatedNotification(notification: NSNotification) {
        // refresh the table view
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return NSKManager.sharedInstance.nearbyTags.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tagCell", forIndexPath: indexPath) as! UITableViewCell
        
        // get the current NSKTag item
        let tag = NSKManager.sharedInstance.nearbyTags[indexPath.row]
        
        if let identifier = tag.tagIdentifier { // tag has data assigned
            cell.textLabel?.text = "Tag identifier: \(identifier)"
        } else { // tag has no data assigned
            if let hwBeacon = tag.hardwareBeacon {
                cell.textLabel?.text = "Tag major: \(hwBeacon.major) minor: \(hwBeacon.minor)"
                
            }
        }
        
        return cell
    }
}
