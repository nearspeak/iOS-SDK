//
//  NSKTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation
import CoreLocation

/// NSCoding Keys
let keyId = "id"
let keyTagDescription = "tagDescription"
let keyTagCategoryId = "tagCategoryId"
let keyTranslation = "translation"
let keyTagIdentifier = "tagIdentifier"
let keyImageURL = "imageURL"
let keyButtonText = "buttonText"
let keyLinkedTags = "linkedTags"
let keyParentId = "parentId"
let keyParentName = "parentName"
let keyParentIdentifier = "parentIdentifier"
let keyTextURL = "textURL"
let keyGender = "gender"
let keyName = "name"

public class NSKTag: NSObject, NSCoding {
    public var id: NSNumber = 0
    public var tagDescription: String?
    public var tagCategoryId: NSNumber?
    public var translation: String?
    public var tagIdentifier: String?
    public var imageURL: NSURL?
    public var buttonText: String?
    public var linkedTags: [NSKLinkedTag]?
    public var parentId: NSNumber?
    public var parentName: String?
    public var parentIdentifier: String?
    public var textURL: NSURL?
    public var gender: String?
    public var name: String?
    public var hardwareBeacon: CLBeacon?

    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    required public init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeIntegerForKey(keyId)
        self.tagDescription = aDecoder.decodeObjectForKey(keyTagDescription) as? String
        self.tagCategoryId = aDecoder.decodeIntegerForKey(keyTagCategoryId)
        self.translation = aDecoder.decodeObjectForKey(keyTranslation) as? String
        self.tagIdentifier = aDecoder.decodeObjectForKey(keyTagIdentifier) as? String
        self.imageURL = aDecoder.decodeObjectForKey(keyImageURL) as? NSURL
        self.buttonText = aDecoder.decodeObjectForKey(keyButtonText) as? String
        //self.linkedTags = aDecoder.decodeObjectForKey(keyLinkedTags)
        self.parentId = aDecoder.decodeIntegerForKey(keyParentId)
        self.parentName = aDecoder.decodeObjectForKey(keyParentName) as? String
        self.parentIdentifier = aDecoder.decodeObjectForKey(keyParentIdentifier) as? String
        self.textURL = aDecoder.decodeObjectForKey(keyTextURL) as? NSURL
        self.gender = aDecoder.decodeObjectForKey(keyGender) as? String
        self.name = aDecoder.decodeObjectForKey(keyName) as? String
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInt(self.id.intValue, forKey: keyId)
        aCoder.encodeObject(self.tagDescription, forKey: keyTagDescription)
        
        if let catId = self.tagCategoryId {
            aCoder.encodeInt(catId.intValue, forKey: keyTagCategoryId)
        }
        
        aCoder.encodeObject(self.translation, forKey: keyTranslation)
        aCoder.encodeObject(self.tagIdentifier, forKey: keyTagIdentifier)
        aCoder.encodeObject(self.imageURL, forKey: keyImageURL)
        aCoder.encodeObject(self.buttonText, forKey: keyButtonText)
        //aCoder.encodeObject(self.linkedTags, forKey: keyLinkedTags)
        
        if let pId = self.parentId {
            aCoder.encodeInt(pId.intValue, forKey: keyParentId)
        }
        
        aCoder.encodeObject(self.parentName, forKey: keyParentName)
        aCoder.encodeObject(self.parentIdentifier, forKey: keyParentIdentifier)
        aCoder.encodeObject(self.textURL, forKey: keyTextURL)
        aCoder.encodeObject(self.gender, forKey: keyGender)
        aCoder.encodeObject(self.name, forKey:keyName)
    }
    
    // MARK: - Helper methods
    
    /**
    Parse a ancestry json string into a array of strings.
    Input looks like: 123/118/20
    
    :param: jsoninput The ancestry json input.
    
    :returns: An array of ancestries.
    */
    public class func parseAncestry(jsoninput: String?) -> [String] {
        if let input = jsoninput {
            return input.componentsSeparatedByString("/")
        }
        
        return []
    }
}
