//
//  NSKLinkedTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

// NSCoding Keys
let keyNSKLinkedTagId = "linkedTag_id"
let keyNSKLinkedTagName = "linkedTag_name"
let keyNSKLinkedTagIdentifier = "linkedTag_identifier"

/**
 Linked nearspeak tags class.
*/
public class NSKLinkedTag: NSObject, NSCoding {
    /** The id of the linked Nearspeak tag. */
    public var id: NSNumber = 0
    
    /** The name of the linked Nearspeak tag. */
    public var name: String?
    
    /** The identifier of the linked Nearspeak tag. */
    public var identifier: String?
    
    /**
     Constructor where you have to set the id of the linked Nearspeak tag.
    
     :param: id The id of the linked Nearspeak tag.
    */
    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    /**
     Constructor for the linked Nearspeak tag.

     :param: id The id of the linked Nearspeak tag.
     :param: name The name of the linked Nearspeak tag.
     :param: identifier The identifier of the linked Nearspeak tag.
    */
    public init(id: NSNumber, name: String, identifier: String) {
        self.id = id
        self.name = name
        self.identifier = identifier
    }
    
    /**
     Standard constructor for the linked Nearspeak tag, with NSCoder support.
    
     :param: aDecoder The NScoder decoder object.
    */
    required public init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeIntegerForKey(keyNSKLinkedTagId)
        self.name = aDecoder.decodeObjectForKey(keyNSKLinkedTagName) as? String
        self.identifier = aDecoder.decodeObjectForKey(keyNSKLinkedTagIdentifier) as? String
    }
    
    /**
     Encode the linked Nearspeak tag for NSCoder.
    
     :param: aCoder The NSCoder encoder object.
    **/
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInt(self.id.intValue, forKey: keyNSKLinkedTagId)
        aCoder.encodeObject(self.name, forKey: keyNSKLinkedTagName)
        aCoder.encodeObject(self.identifier, forKey: keyNSKLinkedTagIdentifier)
    }
}