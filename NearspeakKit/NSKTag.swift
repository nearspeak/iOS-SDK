//
//  NSKTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

public class NSKTag: NSObject {
    public var id: NSNumber?
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

    public init(id: NSNumber) {
        super.init()
        
        self.id = id
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
