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
        
        let stopMonitoringButton = UIBarButtonItem(title: "Stop Monitoring", style: .plain, target: self, action: #selector(DiscoveryTableViewController.stopMonitoring))
        
        self.navigationItem.rightBarButtonItem = stopMonitoringButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupNotifications()
        
        // true: show all beacons, also if the beacon has not data set on the server
        NSKManager.sharedInstance.startBeaconDiscovery(true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSKManager.sharedInstance.stopBeaconDiscovery()
        
        removeNotifications()
    }
    
    // MARK: - Notifications
    
    fileprivate func setupNotifications() {
        // get notifications for if beacons updates appear
        NotificationCenter.default.addObserver(self,
            selector: #selector(DiscoveryTableViewController.onNearbyTagsUpdatedNotification(_:)),
            name: NSNotification.Name(rawValue: NSKConstants.managerNotificationNearbyTagsUpdatedKey),
            object: nil)
        
        // get notification if bluetooth state changes
        NotificationCenter.default.addObserver(self,
            selector: #selector(DiscoveryTableViewController.onBluetoothErrorNotification(_:)),
            name: NSNotification.Name(rawValue: NSKConstants.managerNotificationBluetoothErrorKey),
            object: nil)
        
        // get notifications if location state changes
        NotificationCenter.default.addObserver(self,
            selector: #selector(DiscoveryTableViewController.onLocationErrorNotification(_:)),
            name: NSNotification.Name(rawValue: NSKConstants.managerNotificationLocationErrorKey),
            object: nil)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(DiscoveryTableViewController.onLocationOnlyWhenInUseNotification(_:)),
            name: NSNotification.Name(rawValue: NSKConstants.managerNotificationLocationWhenInUseOnKey),
            object: nil)
    }
    
    fileprivate func removeNotifications() {
        NotificationCenter.default.removeObserver(NSKConstants.managerNotificationNearbyTagsUpdatedKey)
        NotificationCenter.default.removeObserver(NSKConstants.managerNotificationBluetoothErrorKey)
        NotificationCenter.default.removeObserver(NSKConstants.managerNotificationLocationErrorKey)
        NotificationCenter.default.removeObserver(NSKConstants.managerNotificationLocationWhenInUseOnKey)
    }
    
    func onNearbyTagsUpdatedNotification(_ notification: Notification) {
        // refresh the table view
        DispatchQueue.main.async(execute: { () -> Void in
            // copy the nearbyTags from the shared instance
            self.nearbyTags = NSKManager.sharedInstance.nearbyTags
            self.tableView.reloadData()
        })
    }
    
    func onBluetoothErrorNotification(_ notification: Notification) {
        DispatchQueue.main.async(execute: { () -> Void in
            let alertController = UIAlertController(title: "Bluetooth Error", message: "Turn on bluetooth", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    func onLocationErrorNotification(_ notification: Notification) {
        DispatchQueue.main.async(execute: { () -> Void in
            let alertController = UIAlertController(title: "Location Error", message: "Turn on location for this app.", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    func onLocationOnlyWhenInUseNotification(_ notification: Notification) {
        DispatchQueue.main.async(execute: { () -> Void in
            let alertController = UIAlertController(title: "Location Error", message: "Background scanning disabled.", preferredStyle: .alert)
            
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    // MARK: - Beacon Monitoring
    
    func stopMonitoring() {
        NSKManager.sharedInstance.stopBeaconMonitoring()
    }
}

// MARK: - Table view data source

extension DiscoveryTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyTags.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath) 
        
        // get the current NSKTag item
        let tag = nearbyTags[indexPath.row]
        
        cell.textLabel?.text = tag.titleString()
        
        if let uuidString = tag.hardwareBeacon?.proximityUUID.uuidString {
            cell.detailTextLabel?.text = "UUID: " + uuidString
        }
        
        return cell
    }
}
