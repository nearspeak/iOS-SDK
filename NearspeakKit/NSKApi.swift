//
//  NSKApi.swift
//  NearspeakKit
//
//  Created by Patrick Steiner on 21.01.15.
//  Copyright (c) 2015 Mopius OG. All rights reserved.
//

import UIKit

enum HTTPMethod: String {
    case POST = "POST"
    case GET = "GET"
}

/**
 The NearspeakKit API communication class. 
 */
public class NSKApi: NSObject {
    
    /** Set to true if you want to connect to the staging server. */
    private var developmentMode: Bool = false
    
    /** The staging authentication token NSDefaults key. */
    private let kAuthTokenStagingKey = "nsk_auth_token_staging"
    
    /** The production authentication token NSDefaults key. */
    private let kAuthTokenKey = "nsk_auth_token"
    
    /** The URL of the API server. */
    var apiServerURL: String {
        get {
            if (developmentMode) {
                return NSKApiUtils.stagingServer
            } else {
                return NSKApiUtils.productionServer
            }
        }
    }
    
    /** The api authentication token. */
    public var auth_token: String?
    
    private var apiParser = NSKApiParser()
    
    /**
     Init the API object.

     :param: devMode Connect to the staging oder production server.
    */
    public init(devMode: Bool) {
        super.init()
        
        developmentMode = devMode
        
        // load auth token from persistent storage
        self.loadCredentials()
    }
    
    /** Remove the server credentials from the local device. */
    public func logout() {
        auth_token = nil
        saveCredentials()
    }
    
    /** Save the server credentials to the local device. */
    public func saveCredentials() {
        if (developmentMode) {
            NSUserDefaults.standardUserDefaults().setObject(auth_token, forKey: kAuthTokenStagingKey)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(auth_token, forKey: kAuthTokenKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    /** Load the server credentials from the local device. */
    public func loadCredentials() {
        if (developmentMode) {
            auth_token = NSUserDefaults.standardUserDefaults().stringForKey(kAuthTokenStagingKey)
        } else {
            auth_token = NSUserDefaults.standardUserDefaults().stringForKey(kAuthTokenKey)
        }
    }
    
    /** Check if the current user is logged in. */
    public func isLoggedIn() -> Bool {
        if auth_token != nil {
            // TODO: implemented a better check
            return true
        }
        
        return false
    }
    
    // MARK: API calls
    
    /**
     Make the api call to the server

     :param: apiURL The URL of the api call.
     :param: httpMethod The HTTP Method to use for the request.
     :param: params The HTTP Header Parameters.
     :param: requestCompleted The request completion block.
    */
    private func apiCall(apiURL: NSURL, httpMethod: HTTPMethod, params: Dictionary<String, String>?, requestCompleted: (succeeded: Bool, data: NSData?) -> ()) {
        let request = NSMutableURLRequest(URL: apiURL)
        let session = NSURLSession.sharedSession()
        
        switch httpMethod {
        case .POST:
            request.HTTPMethod = httpMethod.rawValue
            
            if let para = params {
                var err : NSError?
                request.HTTPBody = NSJSONSerialization.dataWithJSONObject(para, options: nil, error: &err)
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
            }
        default: // GET
            request.HTTPMethod = httpMethod.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
            if let responseError = error {
                requestCompleted(succeeded: false, data: nil)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    var statusError = NSError(domain: "at.nearspeak", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP status code has unexpected value."])
                    requestCompleted(succeeded: false, data: nil)
                } else {
                    requestCompleted(succeeded: true, data: data)
                }
            }
        })
        
        task.resume()
    }
    
    /**
     API call to get the authentication token from the API server.

     :param: username: The username of the user.
     :param: password: The password of the user.
     :param: requestCompleted The request completion block.
    */
    public func getAuthToken(#username: String, password : String, requestCompleted: (succeeded: Bool, auth_token: String) -> ()) {
        let apiURL = NSURL(string: apiServerURL +  "login/getAuthToken")!
        let params = ["email" : username, "password" : password] as Dictionary<String, String>
        
        apiCall(apiURL, httpMethod: .POST, params: params, requestCompleted: { (succeeded, data) -> () in
            if succeeded {
                self.apiParser.parseGetAuthToken(data!, parsingCompleted: { (succeeded, authToken) -> () in
                    if succeeded {
                        self.auth_token = authToken
                        self.saveCredentials()
                        requestCompleted(succeeded: true, auth_token: authToken)
                    } else {
                        requestCompleted(succeeded: false, auth_token: "")
                    }
                })
            } else {
                requestCompleted(succeeded: false, auth_token: "")
            }
        })
    }
    
    /**
     API call to get all Nearspeak tag from the user.

     :param: requestCompleted The request completion block.
    */
    public func getMyTags(requestCompleted: (succeeded: Bool, tags: [NSKTag]) ->()) {
        if let token = self.auth_token {
            let apiUrl = NSURL(string: apiServerURL + "tags/showMyTags?auth_token=" + token)!
            
            apiCall(apiUrl, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    if let jsonData = data {
                        self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                            if succeeded {
                                requestCompleted(succeeded: true, tags: tags)
                            } else {
                                requestCompleted(succeeded: false, tags: [])
                            }
                            requestCompleted(succeeded: false, tags: [])
                        })
                    } else {
                        requestCompleted(succeeded: false, tags: [])
                    }
                } else {
                    requestCompleted(succeeded: false, tags: [])
                }
            })
        } else {
            println("ERROR: auth token not found")
        }
    }
    
    /**
     API call to get a Nearspeak tag by its tag identifier.

     :param: tagIdentifier The tag identifier of the tag.
     :param: requestCompleted The request completion block.
    */
    public func getTagById(#tagIdentifier: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        // TODO: also submit the current location
        let currentLocale: NSString = NSLocale.preferredLanguages()[0] as! NSString
        let apiUrl = NSURL(string: apiServerURL +  "tags/show?id=" + tagIdentifier + "&lang=" + (currentLocale as String))!
        
        apiCall(apiUrl, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
            if succeeded {
                if let jsonData = data {
                    self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                        if succeeded {
                            if tags.count > 0 {
                                requestCompleted(succeeded: true, tag: tags[0])
                            } else {
                                requestCompleted(succeeded: false, tag: nil)
                            }
                        } else {
                            requestCompleted(succeeded: false, tag: nil)
                        }
                    })
                } else {
                    requestCompleted(succeeded: false, tag: nil)
                }
            } else {
                requestCompleted(succeeded: false, tag: nil)
            }
        })
    }
    
    /**
    API call to get a Nearspeak tag by its hardware identifier.
    
    :param: hardwareIdentifier The hardware identifier of the tag.
    :param: beaconMajorId The iBeacon major id.
    :param: beaconMinorId The iBeacon minor id.
    :param: requestCompleted The request completion block.
    */
    public func getTagByHardwareId(#hardwareIdentifier: String, beaconMajorId: String, beaconMinorId: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        // TODO: also submit the current location
        let currentLocale: String = NSLocale.preferredLanguages().first as! String
        
        var urlString = apiServerURL
        urlString += "tags/showByHardwareId?id=" + formatHardwareId(hardwareIdentifier)
        urlString += "&major=" + beaconMajorId
        urlString += "&minor=" + beaconMinorId
        urlString += "&lang=" + currentLocale
        urlString += "&type=" + NSKTagHardwareType.BLE.rawValue
        
        let apiUrl = NSURL(string: urlString)
        
        apiCall(apiUrl!, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
            if succeeded {
                if let jsonData = data {
                    self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                        if succeeded {
                            if tags.count > 0 {
                                requestCompleted(succeeded: true, tag: tags[0])
                            } else {
                                requestCompleted(succeeded: false, tag: nil)
                            }
                        } else {
                            requestCompleted(succeeded: false, tag: nil)
                        }
                    })
                } else {
                    requestCompleted(succeeded: false, tag: nil)
                }
            } else {
                requestCompleted(succeeded: false, tag: nil)
            }
        })
    }
    /**
     API call to get all supported iBeacon UUIDs.

     :param: requestCompleted The request completion block.
    */
    public func getSupportedBeaconsUUIDs(requestCompleted: (succeeded: Bool, uuids: [String]) ->()) {
        let apiUrl = NSURL(string: apiServerURL + "tags/supportedBeaconUUIDs")!
        
        apiCall(apiUrl, httpMethod: .GET, params: nil) { (succeeded, data) -> () in
            if succeeded {
                if let jsonData = data {
                    self.apiParser.parseUUIDsArray(jsonData, parsingCompleted: { (succeeded, uuids) -> () in
                        if succeeded {
                            requestCompleted(succeeded: true, uuids: uuids)
                        } else {
                            requestCompleted(succeeded: false, uuids: [])
                        }
                    })
                } else {
                    requestCompleted(succeeded: false, uuids: [])
                }
                
            } else {
                requestCompleted(succeeded: false, uuids: [])
            }
        }
    }
    
    //MARK: Helper methods
    
    /**
     Helper method to format the hardware id, which is in the most cases the iBeacon UUID, into the correct format.
    */
    private func formatHardwareId(hardwareId: String) -> String {
        return hardwareId.stringByReplacingOccurrencesOfString("-", withString: "", options: .LiteralSearch, range: nil)
    }
}
