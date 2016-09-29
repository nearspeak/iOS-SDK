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
open class NSKApi: NSObject {
    
    /** Set to true if you want to connect to the staging server. */
    fileprivate var developmentMode: Bool = false
    
    /** The staging authentication token NSDefaults key. */
    fileprivate let kAuthTokenStagingKey = "nsk_auth_token_staging"
    
    /** The production authentication token NSDefaults key. */
    fileprivate let kAuthTokenKey = "nsk_auth_token"
    
    /** The api authentication token. */
    open var auth_token: String?
    
    fileprivate var apiParser = NSKApiParser()
    
    fileprivate var locationManager = NSKLocationManager()
    
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
    open func logout() {
        auth_token = nil
        saveCredentials()
    }
    
    /** Save the server credentials to the local device. */
    open func saveCredentials() {
        if (developmentMode) {
            UserDefaults.standard.set(auth_token, forKey: kAuthTokenStagingKey)
        } else {
            UserDefaults.standard.set(auth_token, forKey: kAuthTokenKey)
        }
        
        UserDefaults.standard.synchronize()
    }
    
    /** Load the server credentials from the local device. */
    open func loadCredentials() {
        if (developmentMode) {
            auth_token = UserDefaults.standard.string(forKey: kAuthTokenStagingKey)
        } else {
            auth_token = UserDefaults.standard.string(forKey: kAuthTokenKey)
        }
    }
    
    /** Check if the current user is logged in. */
    open func isLoggedIn() -> Bool {
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
    fileprivate func apiCall(_ apiURL: URL, httpMethod: HTTPMethod, params: Dictionary<String, String>?, requestCompleted: @escaping (_ succeeded: Bool, _ data: Data?) -> ()) {
        let request = NSMutableURLRequest(url: apiURL)
        let session = URLSession.shared
        
        //let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())
        
        switch httpMethod {
        case .POST:
            request.httpMethod = httpMethod.rawValue
            
            if let para = params {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: para, options: [])
                } catch let error as NSError {
                    request.httpBody = nil
                    Log.error("Api call failed", error)
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
        
        let task = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: NSError?) -> Void in
            if let _ = error {
                requestCompleted(succeeded: false, data: nil)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    //_ = NSError(domain: "at.nearspeak", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP status code has unexpected value."])
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

     - parameter username:: The username of the user.
     - parameter password:: The password of the user.
     - parameter requestCompleted: The request completion block.
    */
    open func getAuthToken(username: String, password : String, requestCompleted: @escaping (_ succeeded: Bool, _ auth_token: String?) -> ()) {
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "login/getAuthToken", queryItems: nil)
        
        if let apiURL = apiComponents.url {
            let params = ["email" : username, "password" : password] as Dictionary<String, String>
            
            apiCall(apiURL, httpMethod: .POST, params: params, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    self.apiParser.parseGetAuthToken(data!, parsingCompleted: { (succeeded, authToken) -> () in
                        if succeeded {
                            self.auth_token = authToken
                            self.saveCredentials()
                            requestCompleted(true, authToken)
                        } else {
                            requestCompleted(false, nil)
                        }
                    })
                } else {
                    requestCompleted(false, nil)
                }
            })
        }
    }
    
    /**
     API call to get all Nearspeak tag from the user.

     - parameter requestCompleted: The request completion block.
    */
    open func getMyTags(_ requestCompleted: @escaping (_ succeeded: Bool, _ tags: [NSKTag]) ->()) {
        if let token = self.auth_token {
            let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/showMyTags", queryItems: [URLQueryItem(name: "auth_token", value: token)])
            
            if let apiURL = apiComponents.url {
                apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
                    if succeeded {
                        if let jsonData = data {
                            self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                                if succeeded {
                                    requestCompleted(true, tags)
                                } else {
                                    requestCompleted(false, [])
                                }
                                requestCompleted(false, [])
                            })
                        } else {
                            requestCompleted(false, [])
                        }
                    } else {
                        requestCompleted(false, [])
                    }
                })
            } else {
                Log.error("Auth token not found")
            }
        }
    }
    
    /**
     API call to get a Nearspeak tag by its tag identifier.

     - parameter tagIdentifier: The tag identifier of the tag.
     - parameter requestCompleted: The request completion block.
    */
    open func getTagById(tagIdentifier: String, requestCompleted: @escaping (_ succeeded: Bool, _ tag: NSKTag?) -> ()) {
        let currentLocale: NSString = Locale.preferredLanguages[0] as NSString
        
        let idQueryItem = URLQueryItem(name: "id", value: tagIdentifier)
        let langQueryItem = URLQueryItem(name: "lang", value: (currentLocale as String))
        let queryItems = [idQueryItem, langQueryItem]
        
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/show", queryItems: queryItems)
        
        if let apiURL = apiComponents.url {
            apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    if let jsonData = data {
                        self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                            if succeeded {
                                if tags.count > 0 {
                                    requestCompleted(true, tags[0])
                                } else {
                                    requestCompleted(false, nil)
                                }
                            } else {
                                requestCompleted(false, nil)
                            }
                        })
                    } else {
                        requestCompleted(false, nil)
                    }
                } else {
                    requestCompleted(false, nil)
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
    open func getTagByHardwareId(hardwareIdentifier: String, beaconMajorId: String, beaconMinorId: String, requestCompleted: @escaping (_ succeeded: Bool, _ tag: NSKTag?) -> ()) {
        let currentLocale: String = Locale.preferredLanguages.first as String!
        
        let idQueryItem = URLQueryItem(name: "id", value: NSKApiUtils.formatHardwareId(hardwareIdentifier))
        let majorQueryItem = URLQueryItem(name: "major", value: beaconMajorId)
        let minorQueryItem = URLQueryItem(name: "minor", value: beaconMinorId)
        let langQueryItem = URLQueryItem(name: "lang", value: currentLocale)
        let typeQueryItem = URLQueryItem(name: "type", value: NSKTagHardwareType.BLE.rawValue)
        let latitudeQueryItem = URLQueryItem(name: "lat", value: "\(locationManager.currentLocation.coordinate.latitude)")
        let longitudeQueryItem = URLQueryItem(name: "lon", value: "\(locationManager.currentLocation.coordinate.longitude)")
        
        let queryItems = [idQueryItem, majorQueryItem, minorQueryItem, langQueryItem, typeQueryItem, latitudeQueryItem, longitudeQueryItem]
        
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/showByHardwareId", queryItems: queryItems)
        
        if let apiURL = apiComponents.url {
            apiCall(apiURL, httpMethod: .GET, params: nil, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    if let jsonData = data {
                        self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                            if succeeded {
                                if tags.count > 0 {
                                    requestCompleted(true, tags.first)
                                } else {
                                    requestCompleted(false, nil)
                                }
                            } else {
                                requestCompleted(false, nil)
                            }
                        })
                    } else {
                        requestCompleted(false, nil)
                    }
                } else {
                    requestCompleted(false, nil)
                }
            })
        }
    }
    /**
     API call to get all supported iBeacon UUIDs.

     - parameter requestCompleted: The request completion block.
    */
    open func getSupportedBeaconsUUIDs(_ requestCompleted: @escaping (_ succeeded: Bool, _ uuids: [String]) ->()) {
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/supportedBeaconUUIDs", queryItems: nil)
        
        if let apiURL = apiComponents.url {
            apiCall(apiURL, httpMethod: .GET, params: nil) { (succeeded, data) -> () in
                if succeeded {
                    if let jsonData = data {
                        self.apiParser.parseUUIDsArray(jsonData, parsingCompleted: { (succeeded, uuids) -> () in
                            if succeeded {
                                requestCompleted(true, uuids)
                            } else {
                                requestCompleted(false, [])
                            }
                        })
                    } else {
                        requestCompleted(false, [])
                    }
                    
                } else {
                    requestCompleted(false, [])
                }
            }
        }
    }
    
    /**
    API call to add a Nearspeak tag.
    
    - parameter tag: The Nearspeak tag which should be added.
    */
    open func addTag(tag: NSKTag, requestCompleted: @escaping (_ succeeded: Bool, _ tag: NSKTag?) -> ()) {
        let currentLocale: String = Locale.preferredLanguages.first as String!
        
        var queryItems = [URLQueryItem]()
        
        queryItems.append(URLQueryItem(name: "lang", value: currentLocale))
        queryItems.append(URLQueryItem(name: "purchase_id", value: "4ea93515-5a84-4add-bf81-293b306b968f")) // default
        
        // translation
        if let translation = tag.translation {
            queryItems.append(URLQueryItem(name: "text", value: translation))
        }
        
        // auth token
        if let token = self.auth_token {
            queryItems.append(URLQueryItem(name: "auth_token", value: token))
        }
        
        // name
        if let name = tag.name {
            queryItems.append(URLQueryItem(name: "name", value: name))
        }
        
        // hardware infos
        if let hardwareID = tag.hardwareBeacon?.proximityUUID.uuidString, let major = tag.hardwareBeacon?.major, let minor = tag.hardwareBeacon?.minor {
            queryItems.append(URLQueryItem(name: "hardware_id", value: NSKApiUtils.formatHardwareId(hardwareID)))
            queryItems.append(URLQueryItem(name: "major", value: "\(major)"))
            queryItems.append(URLQueryItem(name: "minor", value: "\(minor)"))
            queryItems.append(URLQueryItem(name: "hardware_type", value: NSKTagHardwareType.BLE.rawValue))
        }
        
        // location
        let latitude = locationManager.currentLocation.coordinate.latitude
        let longitude = locationManager.currentLocation.coordinate.longitude
        
        if latitude != 0 && longitude != 0 {
            queryItems.append(URLQueryItem(name: "lat", value: "\(locationManager.currentLocation.coordinate.latitude)"))
            queryItems.append(URLQueryItem(name: "lon", value: "\(locationManager.currentLocation.coordinate.longitude)"))
        }
        
        let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/create", queryItems: queryItems)
        
        if let apiURL = apiComponents.url {
            apiCall(apiURL, httpMethod: .POST, params: nil, requestCompleted: { (succeeded, data) -> () in
                if succeeded {
                    if let jsonData = data {
                        self.apiParser.parseTagsArray(jsonData, parsingCompleted: { (succeeded, tags) -> () in
                            if succeeded {
                                if tags.count > 0 {
                                    requestCompleted(true, tags.first)
                                } else {
                                    requestCompleted(false, nil)
                                }
                            } else {
                                requestCompleted(false, nil)
                            }
                        })
                    } else {
                        requestCompleted(false, nil)
                    }
                } else {
                    requestCompleted(false, nil)
                }
            })
        }
    }
    
    /**
     API call to remove a Nearspeak tag.
     
     - parameter tag: The Nearspeak tag which should be added.
     */
    open func removeTag(tag: NSKTag, requestCompleted: @escaping (_ succeeded: Bool) -> ()) {
        if let tagIdentifier = tag.tagIdentifier, let token = auth_token {
            let idQueryItem = URLQueryItem(name: "id", value: tagIdentifier)
            let tokenQueryItem = URLQueryItem(name: "auth_token", value: token)
            let queryItems = [idQueryItem, tokenQueryItem]
            
            let apiComponents = NSKApiUtils.apiURL(developmentMode, path: "tags/delete", queryItems: queryItems)
            
            if let apiURL = apiComponents.url {
                apiCall(apiURL, httpMethod: .POST, params: nil, requestCompleted: { (succeeded, data) -> () in
                    if succeeded {
                        if let jsonData = data {
                            self.apiParser.parseDeleteReponse(jsonData, parsingCompleted: { (succeeded) -> () in
                                if succeeded {
                                    requestCompleted(true)
                                } else {
                                    requestCompleted(false)
                                }
                            })
                        } else {
                            requestCompleted(false)
                        }
                    } else {
                        requestCompleted(false)
                    }
                })
            }
        }
    }
}
