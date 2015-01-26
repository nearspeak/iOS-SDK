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

public class NSKApi: NSObject {
    //MARK: Properties
    private var developmentMode: Bool = true
    
    let kAuthTokenStagingKey = "nsk_auth_token_staging"
    let kAuthTokenKey = "nsk_auth_token"
    
    var apiServerURL: String {
        get {
            if (developmentMode) {
                return NSKApiUtils.stagingServer
            } else {
                return NSKApiUtils.productionServer
            }
        }
    }
    
    var auth_token: String?
    
    var apiParser = NSKApiParser()
    
    public init(devMode: Bool) {
        super.init()
        
        if (devMode) {
            developmentMode = true
        } else {
            developmentMode = false
        }
        
        // load auth token from persistent storage
        self.loadCredentials()
    }
    
    public func logout() {
        auth_token = nil
        saveCredentials()
    }
    
    public func saveCredentials() {
        if (developmentMode) {
            NSUserDefaults.standardUserDefaults().setObject(auth_token, forKey: kAuthTokenStagingKey)
        } else {
            NSUserDefaults.standardUserDefaults().setObject(auth_token, forKey: kAuthTokenKey)
        }
        
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    public func loadCredentials() {
        if (developmentMode) {
            auth_token = NSUserDefaults.standardUserDefaults().stringForKey(kAuthTokenStagingKey)
        } else {
            auth_token = NSUserDefaults.standardUserDefaults().stringForKey(kAuthTokenKey)
        }
    }
    
    public func isLoggedIn() -> Bool {
        if auth_token != nil {
            // TODO: implemented a better check
            return true
        }
        
        return false
    }
    
    //MARK: API calls
    
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
    
    func getAuthToken(#username: String, password : String, requestCompleted: (succeeded: Bool, auth_token: String) -> ()) {
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
    
    func showMyTags(requestCompleted: (succeeded: Bool, tags: [NSKTag]) ->()) {
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
    
    func showTag(#tagIdentifier: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        let currentLocale: NSString = NSLocale.preferredLanguages()[0] as NSString
        let apiUrl = NSURL(string: apiServerURL +  "tags/show?id=" + tagIdentifier + "&lang=" + currentLocale)!
        
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
    
    func showTagByHardwareId(#hardwareIdentifier: String, beaconMajorId: String, beaconMinorId: String, requestCompleted: (succeeded: Bool, tag: NSKTag?) -> ()) {
        let currentLocale: NSString = NSLocale.preferredLanguages()[0] as NSString
        let apiUrl = NSURL(string:
                    apiServerURL +  "tags/showByHardwareId?id=" + hardwareIdentifier +
                        "&major=" + beaconMajorId +
                        "&minor=" + beaconMinorId +
                        "&lang=" + currentLocale +
                        "&type=" + NSKTagHardwareType.BLE.rawValue)!
        
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
}
