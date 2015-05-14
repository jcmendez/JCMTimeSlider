//
//  TimeSliderTestDataSource.swift
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
import TimeSlider

//
//  Represents a test data source that can be initialized with no or some data
//
class TimeSliderTestDataSource: JCMTimeSliderControlDataSource {
    
    let data: [NSDate]?
    
    func numberOfDates() -> Int {
        return data!.count
    }
    
    init(data: [NSDate]?) {
        
        // Init data source with the data we supply (can be empty)
        self.data = data
    }
    
    func dateAtIndex(index: Int) -> NSDate {
        if data!.count > 0 {
            return data![index]
        } else {
            
            //
            //  Data source is empty
            //
            
            // Return current date
            return NSDate(timeIntervalSinceNow: 0);
        }
    }
}
