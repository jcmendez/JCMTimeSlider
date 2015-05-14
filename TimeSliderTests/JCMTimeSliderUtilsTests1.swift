//
//  JCMTimeSliderUtilsTests1.swift
//  TimeSlider
//
//  Created by Larry Pepchuk on 5/12/15.
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


import Foundation
import UIKit
import XCTest
import TimeSlider

//
//  Contains various Unit Tests for JCMTimeSliderUtils methods
//
class JCMTimeSliderUtilsTests1: XCTestCase {
    
    let tsu = JCMTimeSliderUtils()
    
    // Create an empty data source
    var testDataSource = TimeSliderTestDataSource(data: [NSDate]())

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    
    //
    //  Tests TimeMappingPoint struct
    //
    func testTimeMappingPoint() {
        
        let pointZero = TimeMappingPoint(ti:0, y:0.0, index:0)
        let pointTen = TimeMappingPoint(ti:10, y:10.0, index:10)

        
        //
        //  Test 'slopeTo' method
        //
        //  NOTE: index param does not influence slope calculation
        //
        
        // Slope is not defined here (90 degrees, a vertical line) but the method returns zero
        XCTAssertEqual(pointZero.slopeTo(pointZero), 0, "Slope should be 0.0")
        XCTAssertEqual(pointZero.slopeTo(TimeMappingPoint(ti:0, y:1.0, index:10)), 0, "Slope should be 0.0")
        XCTAssertEqual(pointTen.slopeTo(TimeMappingPoint(ti:10, y:0.0, index:10)), 0, "Slope should be 0.0")

        // Slope = 0
        var testPoint = TimeMappingPoint(ti:10, y:0.0, index:10)
        var slope: CGFloat = 0.0
        XCTAssertEqual(pointZero.slopeTo(testPoint), slope, "Slope should match")
        XCTAssertEqual(testPoint.slopeTo(pointZero), slope, "Slope should match")

        // Slope = 0.1
        testPoint = TimeMappingPoint(ti:10, y:1.0, index:10)
        slope = 0.1
        XCTAssertEqual(pointZero.slopeTo(testPoint), slope, "Slope should match")
        XCTAssertEqual(testPoint.slopeTo(pointZero), slope, "Slope should match")
        
        // Slope = 1.0
        testPoint = TimeMappingPoint(ti:1, y:1.0, index:1)
        slope = 1.0
        XCTAssertEqual(pointZero.slopeTo(testPoint), slope, "Slope should match")
        XCTAssertEqual(testPoint.slopeTo(pointZero), slope, "Slope should match")

        testPoint = TimeMappingPoint(ti:10, y:10.0, index:10)
        XCTAssertEqual(pointZero.slopeTo(testPoint), slope, "Slope should match")
        XCTAssertEqual(testPoint.slopeTo(pointZero), slope, "Slope should match")
        
        // Slope = 10.0
        testPoint = TimeMappingPoint(ti:10, y:100.0, index:nil)
        slope = 10.0
        XCTAssertEqual(pointZero.slopeTo(testPoint), slope, "Slope should match")
        XCTAssertEqual(testPoint.slopeTo(pointZero), slope, "Slope should match")
    }
    
}
