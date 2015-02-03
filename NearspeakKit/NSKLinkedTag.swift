//
//  NSKLinkedTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

/// NSCoding Keys
let keyNSKLinkedTagId = "linkedTag_id"
let keyNSKLinkedTagName = "linkedTag_name"
let keyNSKLinkedTagIdentifier = "linkedTag_identifier"

public class NSKLinkedTag: NSObject, NSCoding {
    public var id: NSNumber = 0
    public var name: String?
    public var identifier: String?
    
    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    public init(id: NSNumber, name: String, identifier: String) {
        self.id = id
        self.name = name
        self.identifier = identifier
    }
    
    required public init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeIntegerForKey(keyNSKLinkedTagId)
        self.name = aDecoder.decodeObjectForKey(keyNSKLinkedTagName) as? String
        self.identifier = aDecoder.decodeObjectForKey(keyNSKLinkedTagIdentifier) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInt(self.id.intValue, forKey: keyNSKLinkedTagId)
        aCoder.encodeObject(self.name, forKey: keyNSKLinkedTagName)
        aCoder.encodeObject(self.identifier, forKey: keyNSKLinkedTagIdentifier)
    }
}