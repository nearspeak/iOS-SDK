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
}

/**
The Nearspeak beacon manager class.
*/
public class NSKBeaconManager: NSObject {
    private var nearspeakRegions: NSMutableDictionary = NSMutableDictionary()
    
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
        
        for uuid in uuids {
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.UUIDString)
            
            // notify only if the display is on
            beaconRegion.notifyEntryStateOnDisplay = true
            beaconRegion.notifyOnEntry = false
            beaconRegion.notifyOnExit = true
            
            self.nearspeakRegions[beaconRegion] = NSArray()
        }
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    /**
    Start monitoring for Nearspeak beacons.
    */
    public func startMonitoringForNearspeakBeacons() {
        #if DEBUG
            print("DBG: start monitoring for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop monitoring for Nearspeak beacons.
    */
    public func stopMonitoringForNearspeakBeacons() {
        #if DEBUG
            print("DBG: stop monitoring for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopMonitoringForRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Start ranging for Nearspeak beacons.
    */
    public func startRangingForNearspeakBeacons() {
        #if DEBUG
            print("DBG: start ranging for beacons")
        #endif
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startRangingBeaconsInRegion(beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop ranging for Nearspeak beacons.
    */
    public func stopRangingForNearspeakBeacons() {
        #if DEBUG
            print("DBG: stop ranging for beacons")
        #endif
        
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
            #if DEBUG
                print("Beacon ranging support available")
            #endif
        } else {
            print("ERROR: Beacon ranging support not available")
            
            return false
        }
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedAlways {
            print("ERROR: Can't always get the location")
            
            return false
        }
        
        if centralManager.state == CBCentralManagerState.PoweredOff {
            print("ERROR: Problems with bluetooth")
            
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
                print("DBG: CoreLocation - Location including background support.")
            case .AuthorizedWhenInUse:
                print("DBG: CoreLocation - Location without background support.")
            case .Denied, .NotDetermined, .Restricted:
                print("DBG: CoreLocation - No Location support.")
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
        print("DBG: CoreLocation: didFailWithError: \(error.localizedDescription)")
    }
    
    /**
    * Delegate method, which gets called if you enter a defined region.
    */
    public func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        #if DEBUG
            print("DBG: didEnterRegion")
        #endif
    }
    
    /**
    * Delegate method, which gets called if you exit a defined region.
    */
    public func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        #if DEBUG
            print("DBG: didExitRegion")
        #endif
    }
    
    /**
    * Delegate method, which gets called if monitoring failed for a region.
    */
    public func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        #if DEBUG
            print("DBG: monitoring failed for region")
        #endif
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
                print("DBG: Bluetooth - Powered off")
            case .PoweredOn:
                print("DBG: Bluetooth - Powered on")
            case .Resetting:
                print("DBG: Bluetooth - Resetting")
            case .Unauthorized:
                print("DBG: Bluetooth - Unauthorized")
            case .Unknown:
                print("DBG: Bluetooth - Unknown")
            case .Unsupported:
                print("DBG: Bluetooth - Unsupported")
            }
        #endif
        
        if let myDelegate = delegate {
            myDelegate.beaconManager(self, bluetoothStateDidChange: central.state)
        }
    }
}