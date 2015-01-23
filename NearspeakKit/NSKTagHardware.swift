//
//  NSKTagHardware.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 23.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

enum NSKTagHardwareType: String {
    case QR = "qr"
    case NFC = "nfc"
    case BLE = "ble-beacon"
}

struct NSKTagHardware {
    var hardwareType: NSKTagHardwareType
}
