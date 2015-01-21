//
//  NSKTag.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import Foundation

class NSKTag: NSObject {
    var id: NSNumber?
    var tagDescription: String?
    var tagCategoryId: NSNumber?
    var translation: String?
    var tagIdentifier: String?
    var imageURL: NSURL?
    var buttonText: String?
    var linkedTags: [NSKLinkedTag]?
    var parentId: NSNumber?
    var parentName: String?
    var parentIdentifier: String?
    var textURL: NSURL?
    var gender: String?
    var name: String?
    
    override var description: String {
        return "ID: \(id) - Identifier: \(tagIdentifier)"
    }

    init(id: NSNumber) {
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
    class func parseAncestry(jsoninput: String?) -> [String] {
        if let input = jsoninput {
            return input.componentsSeparatedByString("/")
        }
        
        return []
    }
}
