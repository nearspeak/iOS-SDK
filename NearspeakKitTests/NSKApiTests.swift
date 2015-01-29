//
//  NearspeakKitTests.swift
//  NearspeakKitTests
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import UIKit
import XCTest

class NSKApiTests: XCTestCase {
    
    let api = NSKApi(devMode: false)
    let maxBlockWaitTime: NSTimeInterval = 10
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testApiUrlStrings() {
        XCTAssertEqual("http://nearspeak.cloudapp.net/api/v1/", NSKApiUtils.productionServer, "API: production server url is wrong.");
    }
    
    func testApiGetAuthToken() {
        var apiExpectation = self.expectationWithDescription("API: getAuthToken")
        
        // get username and password from the TestSettings.plist file
        var settingsDictionary: NSDictionary?
        var username = ""
        var password = ""
        
        if let path = NSBundle(forClass: self.dynamicType).pathForResource("TestSettings", ofType: "plist") {
            settingsDictionary = NSDictionary(contentsOfFile: path)
        } else {
            XCTFail("API: getAuthToken no TestSettings.plist file found")
        }

        if let dict = settingsDictionary {
            if let user = dict.valueForKey("ApiUsername") as? String {
                if user == "username@example.com" {
                    XCTFail("API: getAuthToken set correct username in the TestSettings.plist file")
                } else {
                    username = user
                }
            } else {
                XCTFail("API: getAuthToken set a username in the TestSettings.plist file")
            }
            
            if let pwd = dict.valueForKey("ApiPassword") as? String {
                password = pwd
            } else {
                XCTFail("API: getAuthToken set a password in the TestSettings.plist file")
            }
        } else {
            XCTFail("API: getAuthToken failed to parse TestSettings.plist")
        }
        
        api.getAuthToken(username: username, password: password) { (succeeded, auth_token) -> () in
            XCTAssert(succeeded, "API: getAuthToken failed")
            XCTAssertFalse(auth_token.isEmpty, "API: getAuthToken token is empty")
            
            // Check if the token is already stored into the object
            XCTAssertEqual(self.api.auth_token!, auth_token, "API: getAuthToken token not stored")
            
            apiExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(self.maxBlockWaitTime, handler: nil)
    }

    func testApiShow() {
        var apiExpectation = self.expectationWithDescription("API: show")
        
        api.getTagById(tagIdentifier: "3596da33dbf1") { (succeeded, tag) -> () in
            XCTAssert(succeeded, "API: show failed")
            
            self.checkTag(tag)
            
            apiExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(self.maxBlockWaitTime, handler: nil)
    }
    
    func testApiShowByHardwareId() {
        var apiExpectation = self.expectationWithDescription("API: showByHardwareId")

        api.getTagByHardwareId(hardwareIdentifier: "F7826DA6-4FA2-4E98-8024-BC5B71E0893E", beaconMajorId: "62306", beaconMinorId: "5988") { (succeeded, tag) -> () in
            XCTAssert(succeeded, "API: showByHardwareId failed")
            
            self.checkTag(tag)
            
            apiExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(self.maxBlockWaitTime, handler: nil)
    }
    
    /**
     * Test the tag.
     */
    func checkTag(tag: NSKTag?) {
        if let currentTag = tag {
            XCTAssertEqual(currentTag.id.integerValue, 127, "API: show id is different")
            
            if let currentLinkedTags = currentTag.linkedTags {
                XCTAssertEqual(currentLinkedTags.count, 3, "API: show linked tag amount is different")
                
                for linkedTag in currentLinkedTags {
                    checkLinkedTag(linkedTag)
                }
            } else {
                XCTFail("API: show linkedTags array is nil")
            }
        } else {
            XCTFail("API: show tag is nil")
        }
    }
    
    /**
     * Test the linked tag.
     */
    func checkLinkedTag(linkedTag: NSKLinkedTag) {
        XCTAssertGreaterThan(countElements(linkedTag.name), 0, "API: linked tag name is too short")
        XCTAssertGreaterThan(countElements(linkedTag.identifier), 0, "API: linked tag identifier is too short")
    }
}
