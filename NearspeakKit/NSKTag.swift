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
let keyNSKTagId = "tag_id"
let keyNSKTagTagDescription = "tag_Description"
let keyNSKTagTagCategoryId = "tag_tagCategoryId"
let keyNSKTagTranslation = "tag_translation"
let keyNSKTagTagIdentifier = "tag_tagIdentifier"
let keyNSKTagImageURL = "tag_imageURL"
let keyNSKTagButtonText = "tag_buttonText"
let keyNSKTagLinkedTags = "tag_linkedTags"
let keyNSKTagParentId = "tag_parentId"
let keyNSKTagParentName = "tag_parentName"
let keyNSKTagParentIdentifier = "tag_parentIdentifier"
let keyNSKTagTextURL = "tag_textURL"
let keyNSKTagGender = "tag_gender"
let keyNSKTagName = "tag_name"
let keyNSKTagFavorite = "tag_favorite"

public class NSKTag: NSObject, NSCoding {
    /**
     The id of the Tag
    */
    public var id: NSNumber = 0
    public var tagDescription: String?
    public var tagCategoryId: NSNumber?
    public var translation: String?
    public var tagIdentifier: String?
    public var imageURL: NSURL?
    public var buttonText: String?
    public var linkedTags: NSMutableArray = NSMutableArray()
    public var parentId: NSNumber?
    public var parentName: String?
    public var parentIdentifier: String?
    public var textURL: NSURL?
    public var gender: String?
    public var name: String?
    public var hardwareBeacon: CLBeacon?
    public var favorite: Bool = false

    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    required public init(coder aDecoder: NSCoder) {
        self.id = aDecoder.decodeIntegerForKey(keyNSKTagId)
        self.tagDescription = aDecoder.decodeObjectForKey(keyNSKTagTagDescription) as? String
        self.tagCategoryId = aDecoder.decodeIntegerForKey(keyNSKTagTagCategoryId)
        self.translation = aDecoder.decodeObjectForKey(keyNSKTagTranslation) as? String
        self.tagIdentifier = aDecoder.decodeObjectForKey(keyNSKTagTagIdentifier) as? String
        self.imageURL = aDecoder.decodeObjectForKey(keyNSKTagImageURL) as? NSURL
        self.buttonText = aDecoder.decodeObjectForKey(keyNSKTagButtonText) as? String
        self.linkedTags = aDecoder.decodeObjectForKey(keyNSKTagLinkedTags) as! NSMutableArray
        self.parentId = aDecoder.decodeIntegerForKey(keyNSKTagParentId)
        self.parentName = aDecoder.decodeObjectForKey(keyNSKTagParentName) as? String
        self.parentIdentifier = aDecoder.decodeObjectForKey(keyNSKTagParentIdentifier) as? String
        self.textURL = aDecoder.decodeObjectForKey(keyNSKTagTextURL) as? NSURL
        self.gender = aDecoder.decodeObjectForKey(keyNSKTagGender) as? String
        self.name = aDecoder.decodeObjectForKey(keyNSKTagName) as? String
        self.favorite = aDecoder.decodeBoolForKey(keyNSKTagFavorite)
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeInt(self.id.intValue, forKey: keyNSKTagId)
        aCoder.encodeObject(self.tagDescription, forKey: keyNSKTagTagDescription)
        
        if let catId = self.tagCategoryId {
            aCoder.encodeInt(catId.intValue, forKey: keyNSKTagTagCategoryId)
        }
        
        aCoder.encodeObject(self.translation, forKey: keyNSKTagTranslation)
        aCoder.encodeObject(self.tagIdentifier, forKey: keyNSKTagTagIdentifier)
        aCoder.encodeObject(self.imageURL, forKey: keyNSKTagImageURL)
        aCoder.encodeObject(self.buttonText, forKey: keyNSKTagButtonText)
        aCoder.encodeObject(self.linkedTags, forKey: keyNSKTagLinkedTags)
        
        if let pId = self.parentId {
            aCoder.encodeInt(pId.intValue, forKey: keyNSKTagParentId)
        }
        
        aCoder.encodeObject(self.parentName, forKey: keyNSKTagParentName)
        aCoder.encodeObject(self.parentIdentifier, forKey: keyNSKTagParentIdentifier)
        aCoder.encodeObject(self.textURL, forKey: keyNSKTagTextURL)
        aCoder.encodeObject(self.gender, forKey: keyNSKTagGender)
        aCoder.encodeObject(self.name, forKey:keyNSKTagName)
        aCoder.encodeBool(self.favorite, forKey: keyNSKTagFavorite)
    }
    
    // MARK: - Helper methods
    
    /**
     Parse a ancestry json string into a array of strings.
     Input looks like: 123/118/20
    
     @param jsoninput The ancestry json input.
    
     @returns An array of ancestries.
    */
    public class func parseAncestry(jsoninput: String?) -> [String] {
        if let input = jsoninput {
            return input.componentsSeparatedByString("/")
        }
        
        return []
    }
}
