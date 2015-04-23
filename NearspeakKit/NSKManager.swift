//
//  NSKManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 27.01.15.
//  Copyright (c) 2015 Nearspeak. All rights reserved.
//

import UIKit
import CoreLocation
import NearspeakKit

private let _NSKManagerSharedInstance = NSKManager()

public class NSKManager: NSObject, NSKBeaconManagerDelegate {
    
    public class var sharedInstance: NSKManager {
        return _NSKManagerSharedInstance
    }
    
    public let managerNotificationNearbyTagsUpdatedKey = "at.nearspeak.manager.nearbytags.updated"
    
    private let tagQueue = dispatch_queue_create("at.nearspeak.manager.tagQueue", DISPATCH_QUEUE_CONCURRENT)
    
    private var _nearbyTags: [NSKTag] = []
    
    public var nearbyTags: [NSKTag] {
        var nearbyTagsCopy: [NSKTag]!
        
        dispatch_sync(tagQueue) {
            nearbyTagsCopy = self._nearbyTags
        }
        
        return nearbyTagsCopy
    }
    
    private var beaconManager = NSKBeaconManager()
    private var api = NSKApi(devMode: false)
    
    private var showUnassingedBeacons = false
    
    // Current beacons
    private var beacons: [CLBeacon] = []
    
    public override init() {
        super.init()
        
        beaconManager.delegate = self
    }
    
    // MARK: - NearbyBeacons - public
    
    public func startBeaconDiscovery(showUnassingedBeacons: Bool) {
        beaconManager.startMonitoringForNearspeakBeacons()
        beaconManager.startRangingForNearspeakBeacons()
        
        self.showUnassingedBeacons = showUnassingedBeacons
    }
    
    public func stopBeaconDiscovery() {
        beaconManager.stopRangingForNearspeakBeacons()
    }
    
    public func getTagAtIndex(index: Int) -> NSKTag? {
        return _nearbyTags[index]
    }
    
    public func showUnassingedTags(show: Bool) {
        if show != showUnassingedBeacons {
            showUnassingedBeacons = show
            self.removeAllTags()
            self.removeAllBeacons()
        }
    }
    
    // MARK: - NearbyBeacons - private
    
    private func addTagWithBeacon(beacon: CLBeacon) {
        // check if this beacon currently gets added
        for addedBeacon in beacons {
            if beaconsAreTheSame(beaconOne: addedBeacon, beaconTwo: beacon) {
                // beacon is already in the beacon array, update the current tag
                updateTagWithBeacon(beacon)
                return
            }
        }
        // add the new beacon to the waiting array
        beacons.append(beacon)
        
        self.api.getTagByHardwareId(hardwareIdentifier: beacon.proximityUUID.UUIDString, beaconMajorId: beacon.major.stringValue, beaconMinorId: beacon.minor.stringValue) { (succeeded, tag) -> () in
            if succeeded {
                if let currentTag = tag {
                    // set the discovered beacon as hardware beacon on the new tag
                    currentTag.hardwareBeacon = beacon
                    
                    self.addTag(currentTag)
                } else { // beacon is not assigned to a tag in the system
                    self.addUnknownTagWithBeacon(beacon)
                }
            } else { // beacon is not assigned to  a tag in the system
                self.addUnknownTagWithBeacon(beacon)
            }
        }
    }
    
    private func addUnknownTagWithBeacon(beacon: CLBeacon) {
        if showUnassingedBeacons {
            var tag = NSKTag(id: 0)
            tag.name = "Unassigned Tag: \(beacon.major) - \(beacon.minor)"
            tag.hardwareBeacon = beacon
            
            self.addTag(tag)
        }
    }
    
    private func addTag(tag: NSKTag) {
        dispatch_barrier_async(tagQueue, { () -> Void in
            self._nearbyTags.append(tag)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.postContentUpdateNotification()
            })
        })
    }
    
    private func removeTagWithId(id: Int) {
        var index = 0
        
        for tag in self._nearbyTags {
            if tag.id.integerValue == id {
                dispatch_barrier_sync(tagQueue, { () -> Void in
                    self._nearbyTags.removeAtIndex(index)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.postContentUpdateNotification()
                    })
                })
                
                // also remove the beacon from the beacons array
                if let beacon = tag.hardwareBeacon {
                    removeBeacon(beacon)
                }
            }
            
            index++
        }
    }
    
    private func removeBeacon(beacon: CLBeacon) {
        var index = 0
        
        for currentBeacon in beacons {
            if beaconsAreTheSame(beaconOne: beacon, beaconTwo: currentBeacon) {
                self.beacons.removeAtIndex(index)
            }
            
            index++
        }
    }
    
    private func removeAllTags() {
        
        dispatch_barrier_async(tagQueue, { () -> Void in
            self._nearbyTags = []
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.postContentUpdateNotification()
            })
        })
    }
    
    private func removeAllBeacons() {
        self.beacons = []
    }
    
    private func beaconsAreTheSame(#beaconOne: CLBeacon, beaconTwo: CLBeacon) -> Bool {
        if beaconOne.proximityUUID.UUIDString == beaconTwo.proximityUUID.UUIDString {
            if beaconOne.major.longLongValue == beaconTwo.major.longLongValue {
                if beaconOne.minor.longLongValue == beaconTwo.minor.longLongValue {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func getTagByBeacon(beacon: CLBeacon) -> NSKTag? {
        for tag in self._nearbyTags {
            if let hwBeacon = tag.hardwareBeacon {
                if beaconsAreTheSame(beaconOne: hwBeacon, beaconTwo: beacon) {
                    return tag
                }
            }
        }
        
        return nil
    }
    
    private func updateTagWithBeacon(beacon: CLBeacon) {
        if let tag = getTagByBeacon(beacon) {
            tag.hardwareBeacon = beacon
            
            postContentUpdateNotification()
        }
    }
    
    private func processFoundBeacons(beacons: [CLBeacon]) {
        // Add or Update Tags
        for beacon in beacons {
            self.addTagWithBeacon(beacon)
        }
        
        // remove old tags
        for tag in self._nearbyTags {
            var isNewBeacon = false
            
            if let hwBeacon = tag.hardwareBeacon {
                for beacon in beacons {
                    // if the beacon is not found. remove the tag
                    if self.beaconsAreTheSame(beaconOne: beacon, beaconTwo: hwBeacon) {
                        isNewBeacon = true
                    }
                }
            }
            
            if !isNewBeacon {
                removeTagWithId(tag.id.integerValue)
            }
        }
    }
    
    private func postContentUpdateNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(managerNotificationNearbyTagsUpdatedKey, object: nil)
    }
    
    // MARK: - BeaconManager delegate methods
    
    public func beaconManager(manager: NSKBeaconManager!, foundBeacons: [CLBeacon]) {
        self.processFoundBeacons(foundBeacons)
    }
}
