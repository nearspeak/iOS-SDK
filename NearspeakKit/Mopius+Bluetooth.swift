//
//  Mopius+Bluetooth.swift
//
//  Created by Patrick Steiner on 15.09.16.
//  Copyright © 2016 Mopius. All rights reserved.
//

import CoreBluetooth

extension CBCentralManager {
    
    internal var centralManagerState: CBCentralManagerState  {
        get {
            guard let state = CBCentralManagerState(rawValue: state.rawValue) else {
                return .unknown
            }
            return state
        }
    }
}
