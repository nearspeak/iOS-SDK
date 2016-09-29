//
//  NSKTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation
import CoreLocation

// NSCoding Keys
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

/**
 The NSKTag is the tag object model.
*/
open class NSKTag: NSObject, NSCoding {
    /** The id of the tag. */
    open var id: NSNumber = 0
    
    /** The tag description. */
    open var tagDescription: String?
    
    /** The tag category id. */
    open var tagCategoryId: NSNumber?
    
    /** The tag translation. */
    open var translation: String?
    
    /** The tag identifier. */
    open var tagIdentifier: String?
    
    /** The tag image URL. */
    open var imageURL: URL?
    
    /** The tag button text. */
    open var buttonText: String?
    
    /** Array of linked tags. */
    open var linkedTags: NSMutableArray = NSMutableArray()
    
    /** The id of the parent tag. */
    open var parentId: NSNumber?
    
    /** The name of the parent tag. */
    open var parentName: String?
    
    /** The tag identifier of the parent tag. */
    open var parentIdentifier: String?
    
    /** The tag text URL. */
    open var textURL: URL?
    
    /** The tag gender. */
    open var gender: String?
    
    /** The tag name. */
    open var name: String?
    
    /** The hardware beacon object of the tag. */
    open var hardwareBeacon: CLBeacon?
    
    /** True if the tag is a favorite tag. */
    open var favorite: Bool = false

    /**
     Init the tag with an id.

     - parameter id: The id of the tag.
    */

    public init(id: NSNumber) {
        super.init()
        
        self.id = id
    }
    
    /**
     Init the tag and decode the object from NSCoder
    
     - parameter aDecoder: The NScoder decoder object.
    */
    required public init?(coder aDecoder: NSCoder) {
        self.id = NSNumber(aDecoder.decodeInteger(forKey: keyNSKTagId))
        self.tagDescription = aDecoder.decodeObject(forKey: keyNSKTagTagDescription) as? String
        self.tagCategoryId = aDecoder.decodeInteger(forKey: keyNSKTagTagCategoryId) as NSNumber?
        self.translation = aDecoder.decodeObject(forKey: keyNSKTagTranslation) as? String
        self.tagIdentifier = aDecoder.decodeObject(forKey: keyNSKTagTagIdentifier) as? String
        self.imageURL = aDecoder.decodeObject(forKey: keyNSKTagImageURL) as? URL
        self.buttonText = aDecoder.decodeObject(forKey: keyNSKTagButtonText) as? String
        self.linkedTags = aDecoder.decodeObject(forKey: keyNSKTagLinkedTags) as! NSMutableArray
        self.parentId = aDecoder.decodeInteger(forKey: keyNSKTagParentId) as NSNumber?
        self.parentName = aDecoder.decodeObject(forKey: keyNSKTagParentName) as? String
        self.parentIdentifier = aDecoder.decodeObject(forKey: keyNSKTagParentIdentifier) as? String
        self.textURL = aDecoder.decodeObject(forKey: keyNSKTagTextURL) as? URL
        self.gender = aDecoder.decodeObject(forKey: keyNSKTagGender) as? String
        self.name = aDecoder.decodeObject(forKey: keyNSKTagName) as? String
        self.favorite = aDecoder.decodeBool(forKey: keyNSKTagFavorite)
    }
    
    /**
     Encode the tag for NSCoder.

     - parameter aCoder: The NSCoder encoder object.
    **/
    open func encode(with aCoder: NSCoder) {
        aCoder.encodeCInt(self.id.int32Value, forKey: keyNSKTagId)
        aCoder.encode(self.tagDescription, forKey: keyNSKTagTagDescription)
        
        if let catId = self.tagCategoryId {
            aCoder.encodeCInt(catId.int32Value, forKey: keyNSKTagTagCategoryId)
        }
        
        aCoder.encode(self.translation, forKey: keyNSKTagTranslation)
        aCoder.encode(self.tagIdentifier, forKey: keyNSKTagTagIdentifier)
        aCoder.encode(self.imageURL, forKey: keyNSKTagImageURL)
        aCoder.encode(self.buttonText, forKey: keyNSKTagButtonText)
        aCoder.encode(self.linkedTags, forKey: keyNSKTagLinkedTags)
        
        if let pId = self.parentId {
            aCoder.encodeCInt(pId.int32Value, forKey: keyNSKTagParentId)
        }
        
        aCoder.encode(self.parentName, forKey: keyNSKTagParentName)
        aCoder.encode(self.parentIdentifier, forKey: keyNSKTagParentIdentifier)
        aCoder.encode(self.textURL, forKey: keyNSKTagTextURL)
        aCoder.encode(self.gender, forKey: keyNSKTagGender)
        aCoder.encode(self.name, forKey:keyNSKTagName)
        aCoder.encode(self.favorite, forKey: keyNSKTagFavorite)
    }
    
    /**
     Get a formatted title string.

     - returns: An formatted title string or nil.
    */
    open func titleString() -> String {
        if let name = name {
            if name.characters.count > 0 {
                return name
            }
        }
        
        if let translation = translation {
            if translation.characters.count > 0 {
                return translation
            }
        }
        
        if let hardwareBeacon = hardwareBeacon {
            return "Beacon Major ID: \(hardwareBeacon.major) Minor ID: \(hardwareBeacon.minor)"
        }
        
        return NSLocalizedString("No Name", comment: "NSKTag - No Name")
    }
    
    // MARK: - Helper methods
    
    /**
     Parse a ancestry json string into a array of strings.
     Input looks like: 123/118/20
    
     - parameter jsoninput: The ancestry json input.
    
     - returns: An array of ancestries.
    */
    open class func parseAncestry(_ jsoninput: String?) -> [String] {
        if let input = jsoninput {
            return input.components(separatedBy: "/")
        }
        
        return []
    }
}
