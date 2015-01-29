//
//  NSKApiParser.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import UIKit

class NSKApiParser: NSObject {
    
    func parseGetAuthToken(data: NSData, parsingCompleted: (succeeded: Bool, authToken: String) -> ()) {
        let json = JSON(data: data)
        
        if let auth_token = json["auth_token"].string {
            parsingCompleted(succeeded: true, authToken: auth_token)
        } else {
            parsingCompleted(succeeded: false, authToken: "ERROR")
        }
    }
    
    func parseTagsArray(data: NSData, parsingCompleted: (succeeded: Bool, tags: [NSKTag]) -> ()) {
        let json = JSON(data: data)
        
        if let dataArray = json["tags"].array {
            var tags = [NSKTag]()
            
            for tagDict in dataArray {
                var tag = NSKTag(id: tagDict["id"].numberValue)
                
                tag.tagDescription = tagDict["description"].stringValue
                tag.tagCategoryId = tagDict["tag_category_id"].numberValue
                tag.tagIdentifier = tagDict["tag_identifier"].stringValue
                tag.translation = tagDict["translation"]["text"].stringValue
                tag.buttonText = tagDict["button_text"].stringValue
                tag.gender = tagDict["gender"].stringValue
                tag.name = tagDict["name"]["text"].stringValue
                
                // urls
                tag.imageURL = NSURL(string: tagDict["image_url"].stringValue)
                tag.textURL = NSURL(string: tagDict["text_url"].stringValue)
                
                // parent
                tag.parentId = tagDict["parent_tag"]["id"].numberValue
                tag.parentName = tagDict["parent_tag"]["name"].stringValue
                tag.parentIdentifier = tagDict["parent_tag"]["identifier"].stringValue
                
                // linked tags
                var linkedTags = [NSKLinkedTag]()
                
                if let linkedTagsArray = tagDict["linked_tags"].array {
                    for linkedTagDict in linkedTagsArray {                        
                        var id : NSNumber = linkedTagDict["id"].numberValue
                        var name : String = linkedTagDict["name"].stringValue
                        var identifier : String = linkedTagDict["tag_identifier"].stringValue
                        
                        let newLinkedTag = NSKLinkedTag(id: id, name: name, identifier: identifier)
                        
                        linkedTags.append(newLinkedTag)
                    }
                }
                
                tag.linkedTags = linkedTags
                
                tags.append(tag)
            }
            
            parsingCompleted(succeeded: true, tags: tags)
        }
    }
}
