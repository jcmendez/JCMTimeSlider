//
//  ViewController.swift
//  TimeSlider
//
//  Created by Juan C. Mendez on 9/27/14.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2014 Juan C. Mendez (jcmendez@alum.mit.edu)
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

class SampleData: JCMTimeSliderControlDataSource {
    var data: Array<NSDate>?
    
    init(points:Int) {
        let twoYearsAgo=NSDate(timeIntervalSinceNow: -2*365*24*60*60)
        data = randomDatesFrom(twoYearsAgo, to: NSDate(timeIntervalSinceNow: 0), amount: points)
    }
    
    private func randomDatesFrom(from: NSDate, to: NSDate, amount: Int = 25) -> Array<NSDate> {
        var a = Array<NSDate>()
        let diff = to.timeIntervalSinceDate(from)
        for i in 1...amount {
            let randomNumber = arc4random_uniform(UINT32_MAX)
            let randomTimeInterval = diff * Double(randomNumber) / Double(UINT32_MAX)
            a.append(NSDate(timeInterval: randomTimeInterval, sinceDate: from))
        }
        a.sort { (d1, d2) -> Bool in
            return d1.compare(d2) == NSComparisonResult.OrderedAscending
        }
        return a
    }
    
    func numberOfDates() -> Int {
        return data!.count
    }
    
    var hasIcon: Bool = false;
    func dataPointAtIndex(index: Int) -> JCMTimeSliderControlDataPoint {
        
        // Assign approx. half fof the labels to have icons
        if index % 2 == 0 {
            hasIcon = true
        } else {
            hasIcon = false
        }
        return JCMTimeSliderControlDataPoint(date: data![index], hasIcon: hasIcon)
    }
}

class ViewController: UIViewController, JCMTimeSliderControlDelegate {
    
    @IBOutlet var timeControl1: JCMTimeSliderControl?
    @IBOutlet var timeControl2: JCMTimeSliderControl?
    @IBOutlet var timeControl3: JCMTimeSliderControl?
    @IBOutlet var timeControl4: JCMTimeSliderControl?
    
    var sample1 = SampleData(points: 4)
    var sample2 = SampleData(points: 12)
    var sample3 = SampleData(points: 100)
    var sample4 = SampleData(points: 800)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        timeControl1?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        timeControl1?.dataSource = sample1
        timeControl1?.delegate = self
        timeControl1?.tag = 1
        
        timeControl2?.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.4)
        timeControl2?.selectedTickColor = UIColor.blackColor()
        timeControl2?.labelColor = UIColor.blackColor()
        timeControl2?.inactiveTickColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        timeControl2?.dataSource = sample2
        timeControl2?.delegate = self
        timeControl2?.tag = 2
        
        timeControl3?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        timeControl3?.dataSource = sample3
        timeControl3?.delegate = self
        timeControl3?.tag = 3
        
        timeControl4?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        timeControl4?.dataSource = sample4
        timeControl4?.delegate = self
        timeControl4?.tag = 4
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func hoveredOverDate(date: NSDate, index: Int, control: JCMTimeSliderControl) {
        //println("Hovered over control: \(control.tag) -> Date: \(date), loc: \(index)")
    }
    
    func selectedDate(date: NSDate, index: Int, control: JCMTimeSliderControl) {
        //println("Selected control: \(control.tag) -> Date: \(date), loc: \(index)")
    }
    
}

