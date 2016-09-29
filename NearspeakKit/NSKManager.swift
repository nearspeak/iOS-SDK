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
open class NSKManager: NSObject {
    
    /**
     Get the singelton object of this class.
    */
    open class var sharedInstance: NSKManager {
        return _NSKManagerSharedInstance
    }
    
    fileprivate let tagQueue = DispatchQueue(label: "at.nearspeak.manager.tagQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    fileprivate var _nearbyTags = [NSKTag]()
    fileprivate var activeUUIDs = Set<UUID>()
    fileprivate var unkownTagID = -1
    
    /**
     Array of all currently nearby Nearspeak tags.
    */
    open var nearbyTags: [NSKTag] {
        var nearbyTagsCopy = [NSKTag]()
        var tags = [NSKTag]()
        
        tagQueue.sync {
            nearbyTagsCopy = self._nearbyTags
        }
        
        if showUnassingedBeacons {
            return nearbyTagsCopy
        } else {
            for tag in nearbyTagsCopy {
                if let _ = tag.tagIdentifier {
                    tags.append(tag)
                }
            }
        }
        
        return tags
    }
    
    open var unassignedTags: [NSKTag] {
        var nearbyTagsCopy  = [NSKTag]()
        var unassingedTags = [NSKTag]()
        
        tagQueue.sync {
            nearbyTagsCopy = self._nearbyTags
        }
        
        // remove assigend tags
        for tag in nearbyTagsCopy {
            if tag.tagIdentifier == nil {
                unassingedTags.append(tag)
            }
        }
        
        return unassingedTags
    }
    
    fileprivate var api = NSKApi(devMode: false)
    fileprivate var beaconManager: NSKBeaconManager?
    
    fileprivate var showUnassingedBeacons = false
    
    // Current beacons
    fileprivate var beacons = [CLBeacon]()
    
    /**
     The standard constructor.
    */
    public override init() {
        super.init()
        
        setupBeaconManager()
    }
    
    // MARK: - NearbyBeacons - public
    
    /**
    Check if the device has all necessary features enabled to support beacons.
    
    :return: True if all necessary features are enabled, else false.
    */
    open func checkForBeaconSupport() -> Bool {
        if let bManager = beaconManager {
            return bManager.checkForBeaconSupport()
        }
        
        return false
    }
    
    /**
     Add a custom UUID for monitoring.
    */
    open func addCustomUUID(_ uuid: String) {
        if let uuid = UUID(uuidString: uuid) {
            
            var uuids = Set<UUID>()
            uuids.insert(uuid)
            beaconManager?.addUUIDs(uuids)
            
            activeUUIDs.insert(uuid)
        }
    }
    
    /**
     Add the UUIDs from the Nearspeak server.
    */
    open func addServerUUIDs() {
        getActiveUUIDs()
    }
    
    /**
     Start monitoring for iBeacons.
     */
    open func startBeaconMonitoring() {
        if let beaconManager = beaconManager {
            beaconManager.startMonitoringForNearspeakBeacons()
        }
    }
    
    /**
     Stop monitoring for iBeacons.
     */
    open func stopBeaconMonitoring() {
        if let beaconManager = beaconManager {
            beaconManager.stopMonitoringForNearspeakBeacons()
        }
    }
    
    /**
     Start the Nearspeak beacon discovery / ranging.
    
     - parameter showUnassingedBeacons: True if unassinged Nearspeak beacons should also be shown.
    */
    open func startBeaconDiscovery(_ showUnassingedBeacons: Bool) {
        if let bManager = beaconManager {
            bManager.startRangingForNearspeakBeacons()
        }
        
        self.showUnassingedBeacons = showUnassingedBeacons
    }
    
    /**
     Stop the Nearspeak beacon discovery.
    */
    open func stopBeaconDiscovery() {
        if let bManager = beaconManager {
            bManager.stopRangingForNearspeakBeacons()
        }
    }
    
    /**
     Get a Nearspeak tag object from the nearby beacons array.
    
     - parameter index: The index of the Nearspeak tag object.
    */
    open func getTagAtIndex(_ index: Int) -> NSKTag? {
        return _nearbyTags[index]
    }
    
    /**
     Show or hide unassigned Nearspeak tags.
    
     - parameter show: True if unassinged Nearspeak beacons should als be show.
    */
    open func showUnassingedBeacons(_ show: Bool) {
        if show != showUnassingedBeacons {
            showUnassingedBeacons = show
            self.reset()
        }
    }
    
    /**
     Add a demo tag for the simulator.
    */
    open func addDemoTag(_ hardwareIdentifier: String, majorId: String, minorId: String) {
        self.api.getTagByHardwareId(hardwareIdentifier: hardwareIdentifier, beaconMajorId: majorId, beaconMinorId: minorId) { (succeeded, tag) -> () in
            if succeeded {
                if let tag = tag {
                    self.addTag(tag)
                }
            }
        }
    }
    
    /**
     Reset the NSKManager.
    */
    open func reset() {
        self.removeAllTags()
        self.removeAllBeacons()
    }
    
    // MARK: - private
    
    fileprivate func getActiveUUIDs() {
        api.getSupportedBeaconsUUIDs { (succeeded, uuids) -> () in
            if succeeded {
                var newUUIDS = Set<UUID>()
                for uuid in uuids {
                    if newUUIDS.count < NSKApiUtils.maximalBeaconUUIDs {
                        if let id = NSKApiUtils.hardwareIdToUUID(uuid) {
                            newUUIDS.insert(id)
                            self.activeUUIDs.insert(id)
                        }
                    }
                }
                
                if let beaconManager = self.beaconManager {
                    beaconManager.addUUIDs(newUUIDS)
                }
            }
        }
    }
    
    fileprivate func setupBeaconManager() {
        beaconManager = NSKBeaconManager(uuids: activeUUIDs as Set<NSUUID>)
        
        beaconManager!.delegate = self
    }
    
    // MARK: - NearbyBeacons - private
    
    fileprivate func addTagWithBeacon(_ beacon: CLBeacon) {
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
        
        self.api.getTagByHardwareId(hardwareIdentifier: beacon.proximityUUID.uuidString, beaconMajorId: beacon.major.stringValue, beaconMinorId: beacon.minor.stringValue) { (succeeded, tag) -> () in
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
    
    fileprivate func addUnknownTagWithBeacon(_ beacon: CLBeacon) {
        let tag = NSKTag(id: NSNumber(unkownTagID))
        tag.name = "Unassigned Tag: \(beacon.major) - \(beacon.minor)"
        tag.hardwareBeacon = beacon
        
        self.addTag(tag)
        
        unkownTagID -= 1
    }
    
    fileprivate func addTag(_ tag: NSKTag) {
        tagQueue.async(flags: .barrier, execute: { () -> Void in
            self._nearbyTags.append(tag)
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.postContentUpdateNotification()
            })
        })
    }
    
    fileprivate func removeTagWithId(_ id: Int) {
        var index = 0
        
        for tag in _nearbyTags {
            
            if tag.id.intValue == id {
                tagQueue.sync(flags: .barrier, execute: { () -> Void in
                    self._nearbyTags.remove(at: index)
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.postContentUpdateNotification()
                    })
                })
                
                // also remove the beacon from the beacons array
                if let beacon = tag.hardwareBeacon {
                    removeBeacon(beacon)
                }
            }
            
            index += 1
        }
    }
    
    fileprivate func removeBeacon(_ beacon: CLBeacon) {
        var index = 0
        
        for currentBeacon in beacons {
            if beaconsAreTheSame(beaconOne: beacon, beaconTwo: currentBeacon) {
                self.beacons.remove(at: index)
            }
            
            index += 1
        }
    }
    
    fileprivate func removeAllTags() {
        tagQueue.async(flags: .barrier, execute: { () -> Void in
            self._nearbyTags = []
            
            DispatchQueue.main.async(execute: { () -> Void in
                self.postContentUpdateNotification()
            })
        })
    }
    
    fileprivate func removeAllBeacons() {
        self.beacons = []
    }
    
    fileprivate func beaconsAreTheSame(beaconOne: CLBeacon, beaconTwo: CLBeacon) -> Bool {
        if beaconOne.proximityUUID.uuidString == beaconTwo.proximityUUID.uuidString {
            if beaconOne.major.int64Value == beaconTwo.major.int64Value {
                if beaconOne.minor.int64Value == beaconTwo.minor.int64Value {
                    return true
                }
            }
        }
        
        return false
    }
    
    fileprivate func getTagByBeacon(_ beacon: CLBeacon) -> NSKTag? {
        for tag in self._nearbyTags {
            if let hwBeacon = tag.hardwareBeacon {
                if beaconsAreTheSame(beaconOne: hwBeacon, beaconTwo: beacon) {
                    return tag
                }
            }
        }
        
        return nil
    }
    
    fileprivate func updateTagWithBeacon(_ beacon: CLBeacon) {
        if let tag = getTagByBeacon(beacon) {
            tag.hardwareBeacon = beacon
            
            postContentUpdateNotification()
        }
    }
    
    fileprivate func processFoundBeacons(_ beacons: [CLBeacon]) {
        // add or update tags
        for beacon in beacons {
            addTagWithBeacon(beacon)
        }
        
        var tagsToRemove = Set<Int>()
        
        // remove old tags
        for tag in _nearbyTags {
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
                tagsToRemove.insert(tag.id.intValue)
            }
        }
        
        for tagId in tagsToRemove {
            removeTagWithId(tagId)
        }
    }
    
    fileprivate func postContentUpdateNotification() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationNearbyTagsUpdatedKey), object: nil)
    }
}

// MARK: - NSKBeaconManagerDelegate

extension NSKManager: NSKBeaconManagerDelegate {
    /**
    Delegate method which gets called, when new beacons are found.
    */
    public func beaconManager(_ manager: NSKBeaconManager!, foundBeacons: [CLBeacon]) {
        self.processFoundBeacons(foundBeacons)
    }
    
    /**
    Delegate method which gets called, when the bluetooth state changed.
    */
    public func beaconManager(_ manager: NSKBeaconManager!, bluetoothStateDidChange bluetoothState: CBCentralManagerState) {
        switch bluetoothState {
        case .poweredOn:
            NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationBluetoothOkKey), object: nil)
        default:
            NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationBluetoothErrorKey), object: nil)
        }
    }
    
    /**
    Delegate method which gets called, when the location state changed.
    */
    public func beaconManager(_ manager: NSKBeaconManager!, locationStateDidChange locationState: CLAuthorizationStatus) {
        switch locationState {
        case .authorizedAlways:
            NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationLocationAlwaysOnKey), object: nil)
        case .authorizedWhenInUse:
            NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationLocationWhenInUseOnKey), object: nil)
        default:
            NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationLocationErrorKey), object: nil)
        }
    }
    
    /**
     Delegate method which gets called, when a region is entered.
     */
    public func beaconManager(_ manager: NSKBeaconManager, didEnterRegion region: CLRegion) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationRegionEnterKey), object: region, userInfo: ["region" : region])
    }
    
    /**
     Delegate method which gets called, when a region is exited.
     */
    public func beaconManager(_ manager: NSKBeaconManager, didExitRegion region: CLRegion) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationRegionExitKey), object: nil, userInfo: ["region" : region])
    }
    
    /**
     Delegate method which gets called, when new regions are added from the Nearspeak server.
    */
    public func newRegionsAdded(_ manager: NSKBeaconManager) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: NSKConstants.managerNotificationNewRegionAddedKey), object: nil)
    }
}
