//
//  NSKConstants.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 23.04.15.
//  Copyright (c) 2015 Mopius. All rights reserved.
//

import Foundation

/**
 API constants.
*/
public struct NSKConstants {
    // Notification Keys
    
    /** Nearby iBeacon Tag found notification key. */
    public static let managerNotificationNearbyTagsUpdatedKey = "at.nearspeak.manager.nearbytags.updated"
    
    /** Did enter region notification key. */
    public static let managerNotificationRegionEnterKey = "at.nearspeak.manager.region.enter"
    
    /** Did exit region notification key. */
    public static let managerNotificationRegionExitKey = "at.nearspeak.manager.region.exit"
    
    /** New region added from the server. */
    public static let managerNotificationNewRegionAddedKey = "at.nearspeak.manager.region.added"
    
    /** Bluetooth ok key. */
    public static let managerNotificationBluetoothOkKey = "at.nearspeak.manager.bluetooth.ok"
    
    /** Bluetooth error key. */
    public static let managerNotificationBluetoothErrorKey = "at.nearspeak.manager.bluetooth.error"
    
    /** Location always on key. */
    public static let managerNotificationLocationAlwaysOnKey = "at.nearspeak.manager.location.always.on"
    
    /** Location when in use on key. */
    public static let managerNotificationLocationWhenInUseOnKey = "at.nearspeak.manager.location.when.in.use.on"
    
    /** Location error key. */
    public static let managerNotificationLocationErrorKey = "at.nearspeak.manager.location.error"
}
