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
    func beaconManager(_ manager: NSKBeaconManager!, foundBeacons:[CLBeacon])
    
    /**
    This method informs, that there is bluetooth available or not.
    
    - parameter manager: The Nearspeak beacon manager object.
    - parameter bluetoothState: The CoreBluetoothManagerState object.
    */
    func beaconManager(_ manager: NSKBeaconManager!, bluetoothStateDidChange bluetoothState: CBCentralManagerState)
    
    /**
    This method informs, if there is a location available or not.
    
    - parameter manager: The Nearspeak beacon manager object.
    - parameter locationState: The CoreLocation CLAuthorizationStatus object.
    */
    func beaconManager(_ manager: NSKBeaconManager!, locationStateDidChange locationState: CLAuthorizationStatus)
    
    /**
     This method informs, if a region is entered.
     
     - parameter manager: The Nearspeak beacon manager object.
     - parameter region: The CLRegion object.
     */
    func beaconManager(_ manager: NSKBeaconManager, didEnterRegion region: CLRegion)
    
    /**
     This method informs, if a region is exited.
     
     - parameter manager: The Nearspeak beacon manager object.
     - parameter region: The CLRegion object.
     */
    func beaconManager(_ manager: NSKBeaconManager, didExitRegion region: CLRegion)
    
    /**
     This method informs, if new beacons regions are added. So you can restart the region monitoring.
 
     - parameter manager: The Nearspeak beacon manager object.
    */
    func newRegionsAdded(_ manager: NSKBeaconManager)
}

/**
The Nearspeak beacon manager class.
*/
open class NSKBeaconManager: NSObject {
    fileprivate var nearspeakRegions = NSMutableDictionary()
    
    fileprivate let locationManager = CLLocationManager()
    fileprivate var centralManager = CBCentralManager()
    
    /** The delegate object of this class. */
    open var delegate: NSKBeaconManagerDelegate! = nil
    
    /**
    Initializer for this class.
    */
    public init(uuids: Set<UUID>) {
        super.init()
        
        // init the bluetooth stuff
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
        
        addUUIDs(uuids)
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
    }
    
    open func addUUIDs(_ uuids: Set<UUID>) {
        for uuid in uuids {
            let beaconRegion = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.uuidString)
            
            // notify only if the display is on
            beaconRegion.notifyEntryStateOnDisplay = true
            beaconRegion.notifyOnEntry = true
            beaconRegion.notifyOnExit = true
            
            self.nearspeakRegions[beaconRegion] = NSArray()
        }
        
        delegate?.newRegionsAdded(self)
    }
    
    /**
    Start monitoring for Nearspeak beacons.
    */
    open func startMonitoringForNearspeakBeacons() {
        Log.debug("Start monitoring for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startMonitoring(for: beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop monitoring for Nearspeak beacons.
    */
    open func stopMonitoringForNearspeakBeacons() {
        Log.debug("Stop monitoring for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopMonitoring(for: beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Start ranging for Nearspeak beacons.
    */
    open func startRangingForNearspeakBeacons() {
        Log.debug("Start ranging for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.startRangingBeacons(in: beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Stop ranging for Nearspeak beacons.
    */
    open func stopRangingForNearspeakBeacons() {
        Log.debug("Stop ranging for beacons")
        
        for beaconRegion in self.nearspeakRegions {
            locationManager.stopRangingBeacons(in: beaconRegion.key as! CLBeaconRegion)
        }
    }
    
    /**
    Check if beacon support is enabled.
    
    :return: Return true if all necessary features are enabled, otherwise false.
    */
    open func checkForBeaconSupport() -> Bool {
        if CLLocationManager.isRangingAvailable() {
            Log.debug("Beacon ranging support available")
        } else {
            Log.error("Beacon ranging support not available")
            
            return false
        }
        
        if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways {
            Log.error("Can't always get the location")
            
            return false
        }
        
        if centralManager.centralManagerState == CBCentralManagerState.poweredOff {
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
    public func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        self.nearspeakRegions[region] = beacons
        
        let allBeacons = NSMutableArray()
        
        for beaconsArray in self.nearspeakRegions.allValues {
            allBeacons.addObjects(from: beaconsArray as! NSArray as [AnyObject])
        }
        
        delegate?.beaconManager(self, foundBeacons: allBeacons as NSArray as! [CLBeacon])
    }
    
    /**
    Delegate method, which gets called if core location changes its authorization status.
    */
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        #if DEBUG
            switch status {
            case .authorizedAlways:
                Log.debug("CoreLocation - Location including background support.")
            case .authorizedWhenInUse:
                Log.debug("CoreLocation - Location without background support.")
            case .denied, .notDetermined, .restricted:
                Log.debug("CoreLocation - No Location support.")
            }
        #endif
        
        delegate?.beaconManager(self, locationStateDidChange: status)
    }
    
    /**
    Delegate method, which gets called if core location manager fails.
    */
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.error("CoreLocation: didFailWithError", error as NSError?)
    }
    
    /**
    * Delegate method, which gets called if you enter a defined region.
    */
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Log.debug("\(#function)")
        
        delegate?.beaconManager(self, didEnterRegion: region)
    }
    
    /**
    * Delegate method, which gets called if you exit a defined region.
    */
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Log.debug("\(#function)")
        
        delegate?.beaconManager(self, didExitRegion: region)
    }
    
    /**
    * Delegate method, which gets called if monitoring failed for a region.
    */
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Log.error("Monitoring failed for region")
    }
    
    /**
    * Delegate method, which gets called if a region monitoring is started.
    */
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Log.debug("Start Monitoring region: \(region.identifier)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        Log.debug("State: \(state.rawValue) for region: \(region.identifier)")
    }
}

// MARK: - CBCentralManagerDelegate
extension NSKBeaconManager: CBCentralManagerDelegate {
    /**
    Delegate method, which gets called if core bluetooth manager changes its state.
    */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        #if DEBUG
            switch central.centralManagerState {
            case .poweredOff:
                Log.debug("Bluetooth - Powered off")
            case .poweredOn:
                Log.debug("Bluetooth - Powered on")
            case .resetting:
                Log.debug("Bluetooth - Resetting")
            case .unauthorized:
                Log.debug("Bluetooth - Unauthorized")
            case .unknown:
                Log.debug("Bluetooth - Unknown")
            case .unsupported:
                Log.debug("Bluetooth - Unsupported")
            }
        #endif
        
        delegate?.beaconManager(self, bluetoothStateDidChange: central.centralManagerState)
    }
}
