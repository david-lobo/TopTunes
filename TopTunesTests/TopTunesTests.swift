//
//  TopTunesTests.swift
//  TopTunesTests
//
//  Created by david lobo on 24/03/2016.
//  Copyright © 2016 David Lobo. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import TopTunes


class TopTunesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func mockGetItunesFeed(completionHandler: () -> Void) {
        stub(isHost((Constants.apiURL?.host)!) && isPath((Constants.apiURL?.path)!)) { _ in
            completionHandler()
            let stubPath = OHPathForFile("itunes-apple-com-success.json", self.dynamicType)!
            return fixture(stubPath, headers: ["Content-Type":"application/json"])
        }
    }
    
    func testParseDataSuccess() {
        let search = SearchAPI()


        let testBundle = NSBundle(forClass: TopTunesTests.self)
        let url = testBundle.URLForResource("itunes-apple-com-success", withExtension: "json")
        let data = NSData(contentsOfURL: url!)
        
        var tracks: [Track]!
        
        if let data = data {
            
            if let dictionary = search.parseJSON(data) {
                tracks = search.parseDictionary(dictionary)
            }
        }
        
        XCTAssertNotNil(tracks)
        XCTAssertEqual(tracks.count, 10)
        
        let secondArtist = tracks[1]
        
        
        XCTAssertEqual(secondArtist.artistName, "Lukas Graham")
        XCTAssertEqual(secondArtist.name, "7 Years")
        XCTAssertEqual(secondArtist.previewURL, "http://a200.phobos.apple.com/us/r1000/137/Music69/v4/ab/01/99/ab01995b-4c87-fc07-8c85-7d461b2cdfc6/mzaf_9166296509688222028.plus.aac.p.m4a")
        XCTAssertEqual(secondArtist.artworkURL60, "http://is5.mzstatic.com/image/thumb/Music69/v4/1f/57/08/1f57082e-ee7e-dcb7-a73e-ba1f3468211d/093624920496.jpg/60x60bb-85.jpg")
        
        print("firstArtist\(secondArtist.artistName)")
        print("firstTrack\(secondArtist.name)")
        print("firstTrack\(secondArtist.previewURL)")
        print("firstTrack\(secondArtist.artworkURL60)")
        
        for result in tracks {
            XCTAssertNotNil(result)
            XCTAssertNotNil(result.artistName)
            XCTAssertNotNil(result.name)
            XCTAssertNotNil(result.previewURL)
            XCTAssertNotNil(result.artworkURL60)
            
            XCTAssertNotEqual(result.artistName, "")
            XCTAssertNotEqual(result.name, "")
            XCTAssertNotEqual(result.previewURL, "")
            XCTAssertNotEqual(result.artworkURL60, "")
        }
    }
    
    func testGetItunesFeedFailure() {
        
        let expectedError = NSError(domain: (Constants.apiURL?.host)!, code: 404, userInfo: .None)
        stub(isHost((Constants.apiURL?.host)!) && isPath((Constants.apiURL?.path)!)) { _ in
            return OHHTTPStubsResponse(error: expectedError)
        }
        
        let search = SearchAPI()
        let expectation = self.expectationWithDescription("calls the callback with a 404 error")
        
        search.performTopTenMusicSearch(true) { params in
            
            XCTAssertNotNil(params.success)
            XCTAssertFalse(params.success)
            XCTAssertEqual(search.status, SearchAPI.Status.Error)
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(0.3, handler: .None)
        
        OHHTTPStubs.removeAllStubs()
    }
    
    func testGetItunesFeedSuccess() {
        
        mockGetItunesFeed({})
        
        let search = SearchAPI()
        let expectation = self.expectationWithDescription("calls the callback with a success")
        
        search.performTopTenMusicSearch(true) { params in
            
            XCTAssertNil(params.error)
            XCTAssertNotNil(params.success)
            XCTAssertTrue(params.success)
            XCTAssertNotNil(params.results)
            XCTAssertEqual(search.status, SearchAPI.Status.ResultsFound)
            
            if let results = params.results {
                XCTAssertEqual(results.count, 10)
            }
            
            for result in search.results {
                print(result.artistName)
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(0.3, handler: .None)
        
        OHHTTPStubs.removeAllStubs()  
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
