//
//  JCMTimeSliderUtils.swift
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

import Foundation
import QuartzCore

// Slider will accept data source that has not more than this (max) record count
let DATA_SOURCE_MAX_RECORD_COUNT = 1000

/**
*  Used to map time to points and vice versa
*
*   NOTE: 'public' access is required for unit testing (as code runs in a separate module)
*/
public struct TimeMappingPoint {
    
    public var ti: NSTimeInterval
    public var y: CGFloat
    public var index: Int?
    
    //
    //  We must define public initializer to be able to Unit Test the struct
    //
    public init(ti: NSTimeInterval, y: CGFloat, index: Int?) {
        self.ti = ti
        self.y = y
        self.index = index
    }
    
    //
    //  Computes slope for two time mapping points.
    //
    //  Slope is defined as: {time interval difference} / {Y coordinates difference}
    //
    public func slopeTo(other: TimeMappingPoint) -> CGFloat {
        
        // Make sure we don't try to divide by zero
        if other.ti - ti == 0 {
            
            // Officially, slope is not defined here (it is a vertical line)
            return 0.0
        } else {
            return (other.y - y) / CGFloat(other.ti - ti)
        }
    }

    
    //
    //  Creates a new time mapping point using time interval and a slope.
    //
    //  Computes new Y coordinate as: slope * {time interval difference} + y
    //
    public func projectTime(new_ti: NSTimeInterval, slope: CGFloat) -> TimeMappingPoint {
        
        let new_y: CGFloat = slope * CGFloat(new_ti-ti) + y
        
        return TimeMappingPoint(ti: new_ti, y: new_y, index: nil)
    }
    
    //
    //  Creates a new time mapping point using Y coordinate and a slope.
    //
    //  Computes new time interval as: ti + {Y coordinate difference} / slope
    //
    public func projectOffset(new_y: CGFloat, slope: CGFloat) -> TimeMappingPoint {
        
        let new_ti: NSTimeInterval
        
        // Make sure we don't try to divide by zero
        if slope == 0 {
            
            // Officially, time interval is not defined here (zero slope is invalid)
            
            new_ti = 0 // return zero
        } else {
            new_ti = ti + NSTimeInterval((new_y - y) / slope)
        }
        
        return TimeMappingPoint(ti: new_ti, y: new_y, index:nil)
    }
}

public class JCMTimeSliderUtils {
    
    public init() {
        // Initialize elements
    }

    enum BreakPoint : Int {
        case Earliest=0, FirstDistorted, Selected, LastDistorted, Latest
    }

    /**
    Binary search for the index with the closest date to the one passed by parameter
    
    :param: searchItem the date we want to find in the data source
    
    :returns: the index at which we find the closest date available

    NOTE: The method is always expected to find the closest date in the past
    */
    public func findNearestDate(dataSource: JCMTimeSliderControlDataSource?, searchItem :NSDate) -> Int {
        
        assert(dataSource!.numberOfDates() <= DATA_SOURCE_MAX_RECORD_COUNT, "Data source should contain \(DATA_SOURCE_MAX_RECORD_COUNT) records or less")
        
        var lowerIndex = 0;
        var upperIndex = dataSource!.numberOfDates()-1
        
        while (true) {
            var currentIndex = (lowerIndex + upperIndex)/2
            if(dataSource!.dateAtIndex(currentIndex) == searchItem) {
                return currentIndex
            } else if (lowerIndex > upperIndex) {
                return currentIndex
            } else {
                if (dataSource!.dateAtIndex(currentIndex).compare(searchItem) == NSComparisonResult.OrderedDescending) {
                    upperIndex = currentIndex - 1
                } else {
                    lowerIndex = currentIndex + 1
                }
            }
        }
    }

    
    /**
    Linearly converts from a given offset to the corresponding date
    
    :param: from the offset in the control geometry
    
    :returns: the date that corresponds linearly to that offset
    */
    func linearDateFrom(breakPoints: Dictionary<BreakPoint,TimeMappingPoint>, from: CGFloat) -> NSDate {

        let earliest = breakPoints[.Earliest]
        let latest = breakPoints[.Latest]
        let slope = earliest!.slopeTo(latest!)
        let temp = earliest!.projectOffset(from, slope: slope)
        
        return NSDate(timeIntervalSinceReferenceDate:temp.ti)
    }
    
    
    /**
    Every time the data source changes, we call this method to set the end points of the control
    and cache the dates and coordinates of the corresponding points.
    We also call this every time the geometry changes
    The invariant after this call is that breakPoints[.Earliest] and breakPoints[.Latest] will be
    set, either nil if the control is useable (more than 2 dates), or valid TimeMappingPoints
    */
    func setupEndPoints(dataSource: JCMTimeSliderControlDataSource?, breakPoints: Dictionary<BreakPoint,TimeMappingPoint>, frame: CGRect, dataInsets: CGSize) -> Dictionary<BreakPoint,TimeMappingPoint> {
        
        assert(dataSource!.numberOfDates() <= DATA_SOURCE_MAX_RECORD_COUNT, "Data source should contain \(DATA_SOURCE_MAX_RECORD_COUNT) records or less")
        
        var localBreakPoints = breakPoints
        
        localBreakPoints.removeAll(keepCapacity: true)
        
        if let ds = dataSource {
            let numDates = dataSource!.numberOfDates()
            if numDates > 2 {
                let firstDate = dataSource!.dateAtIndex(0)
                let lastDate = dataSource!.dateAtIndex(numDates-1)
                let lowestCoord = dataInsets.height
                let highestCoord = frame.height - 2.0 * dataInsets.height
                localBreakPoints[.Earliest] = TimeMappingPoint(ti: firstDate.timeIntervalSinceReferenceDate, y: lowestCoord, index: 0)
                localBreakPoints[.Latest] = TimeMappingPoint(ti: lastDate.timeIntervalSinceReferenceDate, y: highestCoord, index: numDates-1)
            }
        }
        
        return localBreakPoints
    }

}
