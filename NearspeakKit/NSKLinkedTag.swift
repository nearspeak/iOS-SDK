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
open class NSKLinkedTag: NSObject, NSCoding {
    /** The id of the linked Nearspeak tag. */
    open var id: NSNumber = 0
    
    /** The name of the linked Nearspeak tag. */
    open var name: String?
    
    /** The identifier of the linked Nearspeak tag. */
    open var identifier: String?
    
    /**
     Constructor where you have to set the id of the linked Nearspeak tag.
    
     - parameter id: The id of the linked Nearspeak tag.
    */
    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    /**
     Constructor for the linked Nearspeak tag.

     - parameter id: The id of the linked Nearspeak tag.
     - parameter name: The name of the linked Nearspeak tag.
     - parameter identifier: The identifier of the linked Nearspeak tag.
    */
    public init(id: NSNumber, name: String, identifier: String) {
        self.id = id
        self.name = name
        self.identifier = identifier
    }
    
    /**
     Standard constructor for the linked Nearspeak tag, with NSCoder support.
    
     - parameter aDecoder: The NScoder decoder object.
    */
    required public init?(coder aDecoder: NSCoder) {
        self.id = NSNumber(aDecoder.decodeInteger(forKey: keyNSKLinkedTagId))
        self.name = aDecoder.decodeObject(forKey: keyNSKLinkedTagName) as? String
        self.identifier = aDecoder.decodeObject(forKey: keyNSKLinkedTagIdentifier) as? String
    }
    
    /**
     Encode the linked Nearspeak tag for NSCoder.
    
     - parameter aCoder: The NSCoder encoder object.
    **/
    open func encode(with aCoder: NSCoder) {
        aCoder.encodeCInt(self.id.int32Value, forKey: keyNSKLinkedTagId)
        aCoder.encode(self.name, forKey: keyNSKLinkedTagName)
        aCoder.encode(self.identifier, forKey: keyNSKLinkedTagIdentifier)
    }
}
