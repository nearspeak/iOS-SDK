//
//  NSKManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 27.01.15.
//  Copyright (c) 2015 Nearspeak. All rights reserved.
//

import UIKit
import CoreLocation
import CoreBluetooth

private let _NSKManagerSharedInstance = NSKManager()

/**
 Nearspeak Manager class.
*/
public class NSKManager: NSObject, NSKBeaconManagerDelegate {
    
    /**
     Get the singelton object of this class.
    */
    public class var sharedInstance: NSKManager {
        return _NSKManagerSharedInstance
    }
    
    private let tagQueue = dispatch_queue_create("at.nearspeak.manager.tagQueue", DISPATCH_QUEUE_CONCURRENT)
    
    private var _nearbyTags: [NSKTag] = []
    
    /**
     Array of all currently nearby Nearspeak tags.
    */
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
    
    /**
     The standard constructor.
    */
    public override init() {
        super.init()
        
        beaconManager.delegate = self
        
        // start the beacon monitoring
        beaconManager.startMonitoringForNearspeakBeacons()
    }
    
    // MARK: - NearbyBeacons - public
    
    /**
    Check if the device has all necessary features enabled to support beacons.
    
    :return: True if all necessary features are enabled, else false.
    */
    public func checkForBeaconSupport() -> Bool {
        return beaconManager.checkForBeaconSupport()
    }
    
    /**
     Start the Nearspeak beacon discovery.
    
     :param: showUnassingedBeacons True if unassinged Nearspeak beacons should also be shown.
    */
    public func startBeaconDiscovery(showUnassingedBeacons: Bool) {
        beaconManager.startRangingForNearspeakBeacons()
        
        self.showUnassingedBeacons = showUnassingedBeacons
    }
    
    /**
     Stop the Nearspeak beacon discovery.
    */
    public func stopBeaconDiscovery() {
        beaconManager.stopRangingForNearspeakBeacons()
    }
    
    /**
     Get a Nearspeak tag object from the nearby beacons array.
    
     :param: index The index of the Nearspeak tag object.
    */
    public func getTagAtIndex(index: Int) -> NSKTag? {
        return _nearbyTags[index]
    }
    
    /**
     Show or Hide unassigned Nearspeak tags.
    
     :param: show True if unassinged Nearspeak beacons should als be show.
    */
    public func showUnassingedBeacons(show: Bool) {
        if show != showUnassingedBeacons {
            showUnassingedBeacons = show
            self.removeAllTags()
            self.removeAllBeacons()
        }
    }
    /**
     Add a demo tag for the simualtor.
    */
    public func addDemoTag(hardwareIdentifier: String, majorId: String, minorId: String) {
        self.api.getTagByHardwareId(hardwareIdentifier: hardwareIdentifier, beaconMajorId: majorId, beaconMinorId: minorId) { (succeeded, tag) -> () in
            if succeeded {
                if let tag = tag {
                    self.addTag(tag)
                }
            }
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
        // add or update tags
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
        NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationNearbyTagsUpdatedKey, object: nil)
    }
    
    // MARK: - BeaconManager delegate methods
    
    /**
     Delegate method which gets called, when new beacons are found.
    */
    public func beaconManager(manager: NSKBeaconManager!, foundBeacons: [CLBeacon]) {
        self.processFoundBeacons(foundBeacons)
    }
    
    /**
     Delegate method which gets called, when the bluetooth state changed.
    */
    public func beaconManager(manager: NSKBeaconManager!, bluetoothStateDidChange bluetoothState: CBCentralManagerState) {
        switch bluetoothState {
        case .PoweredOn:
            NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationBluetoothOkKey, object: nil)
        default:
            NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationBluetoothErrorKey, object: nil)
        }
    }
    
    /**
     Delegate method which gets called, when the location state changed.
    */
    public func beaconManager(manager: NSKBeaconManager!, locationStateDidChange locationState: CLAuthorizationStatus) {
        switch locationState {
        case .AuthorizedAlways:
            NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationLocationAlwaysOnKey, object: nil)
        case .AuthorizedWhenInUse:
            NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationLocationWhenInUseOnKey, object: nil)
        default:
            NSNotificationCenter.defaultCenter().postNotificationName(NSKConstants.managerNotificationLocationErrorKey, object: nil)
        }
    }
}
