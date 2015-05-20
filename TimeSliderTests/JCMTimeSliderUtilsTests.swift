//
//  JCMTimeSliderUtilsTests.swift
//  TimeSlider
//
//  Created by Larry Pepchuk on 5/11/15.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Accenture. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import UIKit
import XCTest
import TimeSlider

//
//  Contains Unit Tests for JCMTimeSliderUtils.findNearestDate() method
//
class JCMTimeSliderUtilsTests: XCTestCase {
    
    let tsu = JCMTimeSliderUtils()
    
    // Create an empty data source
    var testDataSource = TimeSliderTestDataSource(data: [JCMTimeSliderControlDataPoint]())

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    //
    //  Tests for 'findNearestDate' method with small data source that has 0,1,2, or 3 records
    //
    //  NOTE: 'findNearestDate' is always expected to find the closest date in the past
    //
    func testFindNearestDate() {
        
        //
        // Empty data source (0 records)
        //
        NSLog("Empty data source (0 records)")

        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: NSDate()), 0,
            "Should return zero for an empty data source")

        //
        // Single data source record (current date)
        //
        NSLog("Single data source record (current date)")
        
        let currentDate = NSDate(timeIntervalSinceNow: 0)

        let oneDayInThePast = currentDate.dateByAddingTimeInterval(-60*60*24)
        let oneDayInThePastM10sec = currentDate.dateByAddingTimeInterval(-60*60*24 - 10)
        let oneDayInThePastP10sec = currentDate.dateByAddingTimeInterval(-60*60*24 + 10)

        let currentDateM10sec = currentDate.dateByAddingTimeInterval(0 - 10)
        let currentDateP10sec = currentDate.dateByAddingTimeInterval(0 + 10)

        let oneDayInTheFuture = currentDate.dateByAddingTimeInterval(60*60*24)
        let oneDayInTheFutureM10sec = currentDate.dateByAddingTimeInterval(60*60*24 - 10)
        let oneDayInTheFutureP10sec = currentDate.dateByAddingTimeInterval(60*60*24 + 10)

        let currentDateDataPoint = JCMTimeSliderControlDataPoint(date: currentDate, hasIcon: false)
        self.testDataSource = TimeSliderTestDataSource(data:[currentDateDataPoint])
        
        // ...same target date
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDate),
            0, "Should match 1st element (zero)")
        
        // ...target date is in the past (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePast),
            0, "Should match 1st element (zero)")
        
        // ...target date is in the future
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInTheFuture),
            0, "Should match 1st element (zero)")
        
        
        // ---- Target date is close but is not an exact match ----
        NSLog("...target date is close but is not an exact match...")
        
        
        // ...target date is current date (10 sec in the past)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateM10sec),
            0, "Should match 2nd element (one)")
        
        // ...target date is current date (10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateP10sec),
            0, "Should match 2nd element (one)")

        //
        // Two data source records (past, current date)
        //
        NSLog("Two data source records (past, current date)")
        
        let oneDayInThePastDataPoint = JCMTimeSliderControlDataPoint(date: oneDayInThePast, hasIcon: false)
        self.testDataSource = TimeSliderTestDataSource(data:[oneDayInThePastDataPoint, currentDateDataPoint])
        
        // ...target date is in the past (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePast),
            0, "Should match 1st element (zero)")
        
        // ...target date is current date (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDate),
            1, "Should match 2nd element (one)")
        
        
        // ---- Target date is close but is not an exact match ----
        NSLog("...target date is close but is not an exact match...")

        
        // ...target date is in the past (shifted 10 sec in the past)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePastM10sec),
            0, "Should match 1st element (zero)")
        
        // ...target date is in the past (shifted 10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePastP10sec),
            0, "Should match 1st element (zero)")

        // ...target date is current date (shifted 10 sec in the past)
        //
        //  NOTE: This is supposed to snap to the previous (older) date even
        //      though the closest date is in the future
        //
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateM10sec),
            0, "Should match 1st element (zero)")
        
        // ...target date is current date (shifted 10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateP10sec),
            1, "Should match 2nd element (one)")
    
        
        //
        // 3 data source records (past, current date, future date)
        //
        let oneDayInTheFutureDataPoint = JCMTimeSliderControlDataPoint(date: oneDayInTheFuture, hasIcon: false)
        self.testDataSource = TimeSliderTestDataSource(data:[
            oneDayInThePastDataPoint,
            currentDateDataPoint,
            oneDayInTheFutureDataPoint])
        
        // ...target date is in the past (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePast),
            0, "Should match 1st element (zero)")
        
        // ...target date is current date (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: NSDate(timeIntervalSinceNow: 0)),
            1, "Should match 2nd element (one)")
        
        // ...target date is in the future (exact match)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInTheFuture),
            2, "Should match 3rd element (two)")
        
        
        // ---- Target date is close but is not an exact match ----
        NSLog("...target date is close but is not an exact match...")

        
        // ...target date is in the past (shifted 10 sec in the past)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePastM10sec),
            0, "Should match 1st element (zero)")
        
        // ...target date is in the past (shifted 10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInThePastP10sec),
            0, "Should match 1st element (zero)")
        
        // ...target date is current date (shifted 10 sec in the past)
        //
        //  NOTE: This is supposed to snap to the previous (older) date even
        //      though the closest date is in the future
        //
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateM10sec),
            0, "Should match 1st element (zero)")
        
        // ...target date is current date (shifted 10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: currentDateP10sec),
            1, "Should match 2nd element (one)")
        
        // ...target date is in the future (shifted 10 sec in the past)
        //
        //  NOTE: This is supposed to snap to the previous (older) date even
        //      though the closest date is in the future
        //
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInTheFutureM10sec),
            1, "Should match 2nd element (one)")
        
        // ...target date is in the future (shifted 10 sec in the future)
        XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
            searchItem: oneDayInTheFutureP10sec),
            2, "Should match 2nd element (one)")
    }
    

    //
    //  Tests for 'findNearestDate' method with data source that has:
    //      - 50 records
    //
    //  NOTE: 'findNearestDate' is always expected to find the closest date in the past
    //
    func testFindNearestDateLargeRecordCount() {

        var recordCount = 5
        performTestFindNearestDate(recordCount)

        recordCount = 50
        performTestFindNearestDate(recordCount)
        
        recordCount = 1000
        performTestFindNearestDate(recordCount)
        
        // Exceed max allowed number of records
        
        //
        //  NOTE: There is currently no easy way to catch an exception/assert during unit testing in Swift.
        //      In objective-C we could use XCTAssertThrows(...) but it does not exists in Swift.
        //
        //  So...
        //      a) if we uncomment the code below, it will crash the app (thus Unit Tests cannot continue)
        //      b) if we keep it commented out, we certanly cannot check for the test condition
        //
        
//        recordCount = 1001
//        createTestDataSource(recordCount)
//        let targetDate = NSDate(timeIntervalSinceNow: 0)
//        
//        // This should throw an assert thus crashing the app (Unit Tests will stop executing)
//        self.tsu.findNearestDate(self.testDataSource, searchItem: targetDate)

    }
    
    
    //
    //  Creates test data source with a given number of records
    //
    func createTestDataSource(recordCount: Int) {
        
        //
        // Prepare data source records (~1/2 in the past, current date, ~1/2 in the future)
        //
        NSLog("data source record count=\(recordCount)")
        
        //
        // Init data source with the given number of records
        //
        //  NOTE: We create records that are one day apart;
        //      half in the past, and half in the future
        //
        let recordCountConverted = NSTimeInterval(recordCount)
        
        var testDataSourceArray:[JCMTimeSliderControlDataPoint] = []
        let startIndex: NSTimeInterval = -((recordCountConverted / 2) - 1)
        let endIndex: NSTimeInterval = startIndex + recordCountConverted
        
        let currentDate = NSDate(timeIntervalSinceNow: 0)
        for var i: NSTimeInterval = startIndex; i < endIndex; i++ {

            let dataPoint = JCMTimeSliderControlDataPoint(date: currentDate.dateByAddingTimeInterval(60*60*24*i), hasIcon: false)
            testDataSourceArray.append(dataPoint)
        }
        self.testDataSource = TimeSliderTestDataSource(data: testDataSourceArray)
        
        XCTAssertEqual(self.testDataSource.numberOfDates(), recordCount, "Data source record count '\(self.testDataSource.numberOfDates())' should match desired record count '\(recordCount)'")
    }
    
    //
    //  Tests for 'findNearestDate' method with data source that has a given number of records
    //
    //  NOTE: 'findNearestDate' is always expected to find the closest date in the past
    //
    func performTestFindNearestDate(recordCount: Int) {
        
        createTestDataSource(recordCount)

        let recordCountConverted = NSTimeInterval(recordCount)
        var testDataSourceArray = NSMutableArray()
        let startIndex: NSTimeInterval = -((recordCountConverted / 2) - 1)
        let endIndex: NSTimeInterval = startIndex + recordCountConverted
        let currentDate = NSDate(timeIntervalSinceNow: 0)

        //
        // Test exact and close matches
        //
        var j = 0
        var targetDate: NSDate
        for var i: NSTimeInterval = startIndex; i < endIndex; i++ {

            // Target date is exact match
            targetDate = currentDate.dateByAddingTimeInterval(60*60*24*i);
            XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
                searchItem: targetDate), j, "Should match current index \(j)")
            
            // Target date is a close match: shifted 10 sec in the past
            targetDate = currentDate.dateByAddingTimeInterval(60*60*24*i - 10);
            XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
                searchItem: targetDate), j - 1 < 0 ? 0 : j - 1, "Should match previous index \(j)")
            
            // Target date is a close match: shifted 10 sec in the future
            targetDate = currentDate.dateByAddingTimeInterval(60*60*24*i + 10);
            XCTAssertEqual(self.tsu.findNearestDate(self.testDataSource,
                searchItem: targetDate), j, "Should match current index \(j)")

            // Move target index to the next record
            j++
        }
    }

}
