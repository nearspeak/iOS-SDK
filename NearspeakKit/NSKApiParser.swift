//
//  NSKApiParser.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import UIKit
import SwiftyJSON

/**
 This class parses the API response objects.
*/
class NSKApiParser: NSObject {
    
    func parseGetAuthToken(data: NSData, parsingCompleted: (succeeded: Bool, authToken: String) -> ()) {
        let json = JSON(data: data)
        
        if let auth_token = json["auth_token"].string {
            parsingCompleted(succeeded: true, authToken: auth_token)
        } else {
            parsingCompleted(succeeded: false, authToken: "ERROR")
        }
    }
    
    func parseUUIDsArray(data: NSData, parsingCompleted: (succeeded: Bool, uuids: [String]) -> ()) {
        let json = JSON(data: data)
        
        if let uuidsData = json["uuids"].array {
            
            let uuids = uuidsData.map { $0.stringValue }
            
            
            parsingCompleted(succeeded: true, uuids: uuids)
        } else {
            parsingCompleted(succeeded: false, uuids: [])
        }
    }
    
    func parseTagsArray(data: NSData, parsingCompleted: (succeeded: Bool, tags: [NSKTag]) -> ()) {
        let json = JSON(data: data)
        
        if let dataArray = json["tags"].array {
            var tags = [NSKTag]()
            
            for tagDict in dataArray {
                let tag = NSKTag(id: tagDict["id"].numberValue)
                
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
                let linkedTags: NSMutableArray = NSMutableArray()
                
                if let linkedTagsArray = tagDict["linked_tags"].array {
                    for linkedTagDict in linkedTagsArray {                        
                        let id : NSNumber = linkedTagDict["id"].numberValue
                        let name : String = linkedTagDict["name"].stringValue
                        let identifier : String = linkedTagDict["tag_identifier"].stringValue
                        
                        let newLinkedTag = NSKLinkedTag(id: id, name: name, identifier: identifier)
                        
                        linkedTags.addObject(newLinkedTag)
                    }
                }
                
                tag.linkedTags = linkedTags as NSMutableArray
                
                tags.append(tag)
            }
            
            parsingCompleted(succeeded: true, tags: tags)
        }
    }
    
    func parseDeleteReponse(data: NSData, parsingCompleted: (succeeded: Bool) -> ()) {
        let json = JSON(data: data)
        
        if json["code"] != nil {
            parsingCompleted(succeeded: false)
        }
        
        parsingCompleted(succeeded: true)
    }
}
