//
//  AppDelegate.swift
//  NearspeakDemo
//
//  Created by Patrick Steiner on 23.04.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import UIKit
import CoreLocation
import NearspeakKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let api = NSKApi(devMode: false)
    var pushedTags = Set<String>()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert, categories: nil))
        
        setupNotifications()
        
        if NSKManager.sharedInstance.checkForBeaconSupport() {
            Log.debug("iBeacons supported")
        } else {
            Log.error("iBeacons not supported")
        }
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    // MARK: - Notifications
    
    private func setupNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onEnterRegionNotification:",
            name: NSKConstants.managerNotificationRegionEnterKey,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onExitRegionNotification:",
            name: NSKConstants.managerNotificationRegionExitKey,
            object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "onNearbyTagsUpdatedNotification:",
            name: NSKConstants.managerNotificationNearbyTagsUpdatedKey,
            object: nil)
    }
    
    func onNearbyTagsUpdatedNotification(notification: NSNotification) {
        // copy the nearbyTags from the shared instance
        let nearbyTags = NSKManager.sharedInstance.nearbyTags
        
        for tag in nearbyTags {
            if let identifier = tag.tagIdentifier {
                api.getTagById(tagIdentifier: identifier, requestCompleted: { (succeeded, tag) -> () in
                    if succeeded {
                        if let tag = tag {
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if !self.pushedTags.contains(identifier) {
                                    self.pushedTags.insert(identifier)

                                    if let bodyText = tag.translation {
                                        self.showLocalPushNotification(title: tag.titleString(), body: bodyText)
                                    } else {
                                        self.showLocalPushNotification(title: tag.titleString(), body: "Default Body")
                                    }
                                }
                            })
                        }
                    }
                })
            }
        }
    }
    
    func onEnterRegionNotification(notification: NSNotification) {
        // start discovery to get more infos about the beacon
        NSKManager.sharedInstance.startBeaconDiscovery(false)
    }
    
    func onExitRegionNotification(notification: NSNotification) {
        // stop discovery
        NSKManager.sharedInstance.stopBeaconDiscovery()
        
        // reset already pushed tags
        pushedTags.removeAll()
    }
    
    private func showLocalPushNotification(title notificationTitle: String, body notificationText: String) {
        let notification = UILocalNotification()
        
        notification.alertTitle = notificationTitle
        
        if notificationText.isEmpty {
            notification.alertBody = "Default Body Text"
        } else {
            notification.alertBody = notificationText
        }
        
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
}

