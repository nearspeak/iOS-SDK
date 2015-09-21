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
    
    /** The api authentication token. */
    public var auth_token: String?
    
    private var apiParser = NSKApiParser()
    
    private var locationManager = NSKLocationManager()
    
    /**
     Init the API object.

     - parameter devMode: Connect to the staging oder production server.
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

     - parameter apiURL: The URL of the api call.
     - parameter httpMethod: The HTTP Method to use for the request.
     - parameter params: The HTTP Header Parameters.
     - parameter requestCompleted: The request completion block.
    */
    private func apiCall(apiURL: NSURL, httpMethod: HTTPMethod, params: Dictionary<String, String>?, requestCompleted: (succeeded: Bool, data: NSData?) -> ()) {
        let request = NSMutableURLRequest(URL: apiURL)
        let session = NSURLSession.sharedSession()
        
        //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        switch httpMethod {
        case .POST:
            request.HTTPMethod = httpMethod.rawValue
            
            if let para = params {
                do {
                    request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(para, options: [])
                } catch let error as NSError {
                    request.HTTPBody = nil
                    print("ERROR: \(error.localizedDescription)")
                }
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                request.addValue("application/json", forHTTPHeaderField: "Accept")
            }
        default: // GET
            // GET is the default value
            //request.HTTPMethod = httpMethod.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
        }
        
        let task = session.dataTaskWithRequest(request) { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let _ = error {
                requestCompleted(succeeded: false, data: nil)
            } else if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    //_ = NSError(domain: "at.nearspeak", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP status code has unexpected value."])
                    requestCompleted(succeeded: false, data: nil)
                } else {
                    requestCompleted(succeeded: true, data: data)
                }
            }
        }
        
        task.resume()
    }
    
    /**
     API call to get the authentication token from the API server.

     - parameter username:: The username of the user.
     - parameter password:: The password of the user.
     - parameter requestCompleted: The request completion block.
    */
    public func getAuthToken(username username: String, password : String, requestCompleted: (succeeded: Bool, auth_token: String?) -> ()) {
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "login/getAuthToken", queryItems: nil)
        
        if let apiURL = apiComponents.URL {
            let params = ["email" : username, "password" : password] as Dictionary<String, String>
            
            apiCall(apiURL, httpMethod: .POST, params: params, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    self.apiParser.parseGetAuthToken(data!, parsingCompleted: { (succeeded, authToken) -> () in
                        if succeeded {
                            self.auth_token = authToken
                            self.saveCredentials()
                            requestCompleted(succeeded: true, auth_token: authToken)
                        } else {
                            requestCompleted(succeeded: false, auth_token: nil)
                        }
                    })
                } else {
                    requestCompleted(succeeded: false, auth_token: nil)
                }
            })
        }
    }
    
    /**
     API call to get all Nearspeak tag from the user.

     - parameter requestCompleted: The request completion block.
    */
    public func getMyTags(requestCompleted: (succeeded: Bool, tags: [NSKTag]) ->()) {
        if let token = self.auth_token {
            let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/showMyTags", queryItems: [NSURLQueryItem(name: "auth_token", value: token)])
            
            if let apiURL = apiComponents.URL {
                apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
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
                print("ERROR: auth token not found")
            }
        }
    }
    
    /**
     API call to get a Nearspeak tag by its tag identifier.

     - parameter tagIdentifier: The tag identifier of the tag.
     - parameter requestCompleted: The request completion block.
    */
    public func getTagById(tagIdentifier tagIdentifier: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        let currentLocale: NSString = NSLocale.preferredLanguages()[0] as NSString
        
        let idQueryItem = NSURLQueryItem(name: "id", value: tagIdentifier)
        let langQueryItem = NSURLQueryItem(name: "lang", value: (currentLocale as String))
        let queryItems = [idQueryItem, langQueryItem]
        
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/show", queryItems: queryItems)
        
        if let apiURL = apiComponents.URL {
            apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
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
    }
    
    /**
    API call to get a Nearspeak tag by its hardware identifier.
    
    - parameter hardwareIdentifier: The hardware identifier of the tag.
    - parameter beaconMajorId: The iBeacon major id.
    - parameter beaconMinorId: The iBeacon minor id.
    - parameter requestCompleted: The request completion block.
    */
    public func getTagByHardwareId(hardwareIdentifier hardwareIdentifier: String, beaconMajorId: String, beaconMinorId: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        let currentLocale: String = NSLocale.preferredLanguages().first as String!
        
        let idQueryItem = NSURLQueryItem(name: "id", value: NSKApiUtils.formatHardwareId(hardwareIdentifier))
        let majorQueryItem = NSURLQueryItem(name: "major", value: beaconMajorId)
        let minorQueryItem = NSURLQueryItem(name: "minor", value: beaconMinorId)
        let langQueryItem = NSURLQueryItem(name: "lang", value: currentLocale)
        let typeQueryItem = NSURLQueryItem(name: "type", value: NSKTagHardwareType.BLE.rawValue)
        let latitudeQueryItem = NSURLQueryItem(name: "lat", value: "\(locationManager.currentLocation.coordinate.latitude)")
        let longitudeQueryItem = NSURLQueryItem(name: "lon", value: "\(locationManager.currentLocation.coordinate.longitude)")
        
        let queryItems = [idQueryItem, majorQueryItem, minorQueryItem, langQueryItem, typeQueryItem, latitudeQueryItem, longitudeQueryItem]
        
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/showByHardwareId", queryItems: queryItems)
        
        if let apiURL = apiComponents.URL {
            apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
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
    }
    /**
     API call to get all supported iBeacon UUIDs.

     - parameter requestCompleted: The request completion block.
    */
    public func getSupportedBeaconsUUIDs(requestCompleted: (succeeded: Bool, uuids: [String]) ->()) {
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/supportedBeaconUUIDs", queryItems: nil)
        
        if let apiURL = apiComponents.URL {
            apiCall(apiURL, httpMethod: .GET, params: nil) { (succeeded, data) -> () in
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
    }
}
