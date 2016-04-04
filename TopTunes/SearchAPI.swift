//
//  SearchAPI.swift
//  TopMusic
//
//  Created by david lobo on 18/03/2016.
//  Copyright © 2016 David Lobo. All rights reserved.
//

import UIKit

//*****************************************************************
// SearchAPI
//*****************************************************************

// Helper class for loading data feed from iTunes and parsing the 
// response as JSON data

class SearchAPI {
    
    typealias SearchComplete = (success: Bool, results: [Track]?, error: NSError?) -> Void
    
    private var dataTask: NSURLSessionDataTask? = nil
    
    enum Status {
        case NotSearched
        case Searching
        case NoResultsFound
        case ResultsFound
        case Error
    }
    
    private(set) var status: Status = .NotSearched
    private(set) var results: [Track] = []
    private var currentError: NSError!
    
    //*****************************************************************
    // Load remote JSON data and parse it
    //*****************************************************************
    
    func performTopTenMusicSearch(cacheEnabled: Bool, completion: SearchComplete ) {
        
            dataTask?.cancel()
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            status = .Searching
        
            let session: NSURLSession
            if cacheEnabled {
                
                // Use the default cache policy
                session = NSURLSession.sharedSession()
            } else {
                
                // Use a custom policy to disable cache
                let config = NSURLSessionConfiguration.defaultSessionConfiguration()
                config.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringCacheData
                session = NSURLSession(configuration: config)
            }
        
            if let apiURL = Constants.apiURL {
                dataTask = session.dataTaskWithURL(apiURL, completionHandler: {
                    data, response, error in
                    
                    self.status = .NotSearched
                    var success = false
                    self.currentError = nil
                    
                    if let error = error {
                        self.status = .Error
                        self.currentError = error
                    } else {
                        if response != nil {
                            if let httpResponse = response as? NSHTTPURLResponse where httpResponse.statusCode == 200 {
                                if let data = data, dictionary = self.parseJSON(data) {
                                    let searchResults = self.parseDictionary(dictionary)
                                    
                                    if searchResults.isEmpty {
                                        self.status = .NoResultsFound
                                    } else {
                                        self.status = .ResultsFound
                                    }
                                    success = true
                                    self.results = searchResults
                                }
                            } else {
                                self.status = .Error
                            }
                        } else {
                            self.status = .Error
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        completion(success: success, results: self.results, error: self.currentError)
                    })
                })
                dataTask?.resume()
            }
        }
    
    //*****************************************************************
    // Convert to a JSON object
    //*****************************************************************
    
    internal func parseJSON(data: NSData) -> [String: AnyObject]? {
        do {
            return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject]
        } catch {
            return nil
        }
    }
    
    //*****************************************************************
    // Parse the results
    //*****************************************************************
    
    internal func parseDictionary(dictionary: [String: AnyObject]) -> [Track] {
        guard let feedArray = dictionary["feed"] as? [String: AnyObject],
        let entryArray = feedArray["entry"] as? [AnyObject]
            
        else {
            return []
        }
        
        var searchResults = [Track]()
        
        for resultDict in entryArray {
            
            if let resultDict = resultDict as? [String: AnyObject] {
                var searchResult: Track?
                searchResult = parseTrack(resultDict)

                if let result = searchResult {
                    searchResults.append(result)
                }
            }
        }
        return searchResults
    }
    
    //*****************************************************************
    // Parse the result to a SearchResult object
    //*****************************************************************
    
    internal func parseTrack(dictionary: [String: AnyObject]) -> Track {
        
        let searchResult = Track()
        
        if let nameDict = dictionary["im:name"] as? [String: AnyObject] {
            if let name = nameDict["label"] as? String {
                searchResult.name = name
            }
        }
        
        if let nameDict = dictionary["im:artist"] as? [String: AnyObject] {
            if let artistName = nameDict["label"] as? String {
                searchResult.artistName = artistName
            }
        }
        
        if let linkArray = dictionary["link"] as? [AnyObject] {
            
            for linkDict in linkArray {
                
                if let linkDict = linkDict as? [String: AnyObject],
                    let linkAttr = linkDict["attributes"] as? [String: AnyObject] {
                        
                    if let linkType = linkAttr["type"] as? String,
                        let href = linkAttr["href"] as? String {
                         
                        if let linkAssetType = linkAttr["im:assetType"] as? String {
                            if linkAssetType == "preview" && linkType == "audio/x-m4a" {
                                searchResult.previewType = linkType
                                searchResult.previewURL = NSURL(string: href)
                            }
                        } else if linkType == "text/html" {
                            searchResult.storeURL = NSURL(string: href)
                        }
                    }
                }
            }
        }
        
        if let imageArray = dictionary["im:image"] as? [AnyObject] {
            for imageDict in imageArray {
                
                if let imageDict = imageDict as? [String: AnyObject],
                    let imageAttr = imageDict["attributes"] as? [String: AnyObject],
                    let imageLabel = imageDict["label"] as? String {
                    
                    if let imageHeight = imageAttr["height"] as? String {
                        if imageHeight == "60" {
                            searchResult.artworkURL60 = NSURL(string: imageLabel)
                        } else if imageHeight == "170" {
                            searchResult.artworkURL170 = NSURL(string: imageLabel)
                        }
                    }
                }
            }
        }

        return searchResult
    }
}