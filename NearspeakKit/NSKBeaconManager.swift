//
//  NSKBeaconManager.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 16.12.14.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

/*
* Ranging infos:
* http://stackoverflow.com/questions/19246493/locationmanagerdidenterregion-not-called-when-a-beacon-is-detected
*/

import UIKit
import CoreLocation
import CoreBluetooth

/**
Delegate protocol for the Nearspeak beacon manager class.
*/
public protocol NSKBeaconManagerDelegate {
    /**
    This method informs, that there are new found beacons available.
    
    - parameter manager: The Nearspeak beacon manager object.
    - parameter foundBeacons: An array with CLBeacon objects.
    */
    func beaconManager(manager: NSKBeaconManager!, foundBeacons:[CLBeacon])
    
    /**
    This method informs, that there is bluetooth available or not.
    
    - parameter manager: The Nearspeak beacon manager object.
    - parameter bluetoothState: The CoreBluetoothManagerState object.
    */
    func beaconManager(manager: NSKBeaconManager!, bluetoothStateDidChange bluetoothState: CBCentralManagerState)
    
    /**
    This method informs, if there is a location available or not.
    
    - parameter manager: The Nearspeak beacon manager object.
    - parameter locationState: The CoreLocation CLAuthorizationStatus object.
    */
    func beaconManager(manager: NSKBeaconManager!, locationStateDidChange locationState: CLAuthorizationStatus)
    
    /**
     This method informs, if a region is entered.
     
     - parameter manager: The Nearspeak beacon manager object.
     - parameter region: The CLRegion object.
     */
    func beaconManager(manager: NSKBeaconManager, didEnterRegion region: CLRegion)
    
    /**
     This method informs, if a region is exited.
     
     - parameter manager: The Nearspeak beacon manager object.
     - parameter region: The CLRegion object.
     */
    func beaconManager(manager: NSKBeaconManager, didExitRegion region: CLRegion)
    
    /**
     This method informs, if new beacons regions are added. So you can restart the region monitoring.
 
     - parameter manager: The Nearspeak beacon manager object.
    */
    func newRegionsAdded(manager: NSKBeaconManager)
}

/**
The Nearspeak beacon manager class.
*/
public class NSKBeaconManager: NSObject {
    private var nearspeakRegions = NSMutableDictionary()
    
    private let locationManager = CLLocationManager()
    private var centralManager = CBCentralManager()
    
    /** The delegate object of this class. */
    public var delegate: NSKBeaconManagerDelegate! = nil
    
    /**
    Initializer for this class.
    */
    public init(uuids: Set<NSUUID>) {
        super.init()
        
        // init the bluetooth stuff
        centralManager = CBCentralManager(delegate: self, queue: dispatch_get_main_queue())
        
        addUUIDs(uuids)
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    public func addUUIDs(uuids: Set<NSUUID>) {
        for uuid in uuids {
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            
            // notify only if the display is on
            beaconRegion.notifyEntryStateOnDisplay = true
            beaconRegion.notifyOnEntry = true
            beaconRegion.notifyOnExit = true
            
            self.nearspeakRegions[beaconRegion] = NSArray()
        }
        
        delegate!.newRegionsAdded(self)
    }
    
    /**
    Start monitoring for Nearspeak beacons.
    */
    public func startMonitoringForNearspeakBeacons() {
        Log.debug("Start monitoring for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop monitoring for Nearspeak beacons.
    */
    public func stopMonitoringForNearspeakBeacons() {
        Log.debug("Stop monitoring for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Start ranging for Nearspeak beacons.
    */
    public func startRangingForNearspeakBeacons() {
        Log.debug("Start ranging for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop ranging for Nearspeak beacons.
    */
    public func stopRangingForNearspeakBeacons() {
        Log.debug("Stop ranging for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Check if beacon support is enabled.
    
    :return: Return true if all necessary features are enabled, otherwise false.
    */
    public func checkForBeaconSupport() -> Bool {
        if CLLocationManager.isRangingAvailable() {
            Log.debug("Beacon ranging support available")
        } else {
            Log.error("Beacon ranging support not available")
            
            return false
        }
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
            Log.error("Can't always get the location")
            
            return false
        }
        
        if centralManager.state == CBCentralManagerState.PoweredOff {
            Log.error("Problems with bluetooth")
            
            return false
        }
        
        return true
    }
}

// MARK: - CLLocationManagerDelegate

extension NSKBeaconManager: CLLocationManagerDelegate {
    /**
    Delegate method, which gets called if you access a new beacon region.
    */
    public func locationManager(manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], inRegion region: CLBeaconRegion) {
        self.nearspeakRegions[region] = beacons
        
        let allBeacons = NSMutableArray()
        
        for beaconsArray in self.nearspeakRegions.allValues {
            allBeacons.addObjectsFromArray(beaconsArray as! NSArray as [AnyObject])
        }
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, foundBeacons: allBeacons as NSArray as! [CLBeacon])
        }
    }
    
    /**
    Delegate method, which gets called if core location changes its authorization status.
    */
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        #if DEBUG
            switch status {
            case .AuthorizedAlways:
                Log.debug("CoreLocation - Location including background support.")
            case .AuthorizedWhenInUse:
                Log.debug("CoreLocation - Location without background support.")
            case .Denied, .NotDetermined, .Restricted:
                Log.debug("CoreLocation - No Location support.")
            }
        #endif
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, locationStateDidChange: status)
        }
    }
    
    /**
    Delegate method, which gets called if core location manager fails.
    */
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        Log.error("CoreLocation: didFailWithError", error)
    }
    
    /**
    * Delegate method, which gets called if you enter a defined region.
    */
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Log.debug("\(#function)")
        
        if let _ = delegate {
            delegate!.beaconManager(self, didEnterRegion: region)
        }
    }
    
    /**
    * Delegate method, which gets called if you exit a defined region.
    */
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log.debug("\(#function)")
        
        if let _ = delegate {
            delegate!.beaconManager(self, didExitRegion: region)
        }
    }
    
    /**
    * Delegate method, which gets called if monitoring failed for a region.
    */
    public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        Log.error("Monitoring failed for region")
    }
    
    /**
    * Delegate method, which gets called if a region monitoring is started.
    */
    public func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {
        Log.debug("Start Monitoring region: \(region.identifier)")
    }
    
    public func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        Log.debug("State: \(state.rawValue) for region: \(region.identifier)")
    }
}

// MARK: - CBCentralManagerDelegate
extension NSKBeaconManager: CBCentralManagerDelegate {
    /**
    Delegate method, which gets called if core bluetooth manager changes its state.
    */
    public func centralManagerDidUpdateState(central: CBCentralManager) {
        #if DEBUG
            switch central.state {
            case .PoweredOff:
                Log.debug("Bluetooth - Powered off")
            case .PoweredOn:
                Log.debug("Bluetooth - Powered on")
            case .Resetting:
                Log.debug("Bluetooth - Resetting")
            case .Unauthorized:
                Log.debug("Bluetooth - Unauthorized")
            case .Unknown:
                Log.debug("Bluetooth - Unknown")
            case .Unsupported:
                Log.debug("Bluetooth - Unsupported")
            }
        #endif
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, bluetoothStateDidChange: central.state)
        }
    }
}