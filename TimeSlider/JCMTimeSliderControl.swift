//
//  JCMTimeSliderControl.swift
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
import QuartzCore

/**
*  Protocol that must be implemented by any data source for this control.  Note that the
*  data source must guarantee that the dates are sorted ascending
*/
protocol JCMTimeSliderControlDataSource {
  func numberOfDates() -> Int
  func dateAtIndex(index: Int) -> NSDate
}

@objc protocol JCMTimeSliderControlDelegate {
  optional func selectedDate(date:NSDate, index:Int, control:JCMTimeSliderControl)
  optional func hoveredOverDate(date:NSDate, index:Int, control:JCMTimeSliderControl)
}

class JCMTimeSliderControl: UIControl, UIDynamicAnimatorDelegate, JCMTimeSliderControlDataSource {

  required init(coder aDecoder: NSCoder) {
    // Initialize our added elements
    expanded = false
    expansionChangeNeeded = false
    super.init(coder: aDecoder)
    clipsToBounds = true
    snapAnimUIDynamicAnimator = UIDynamicAnimator(referenceView: self)
    snapAnimUIDynamicAnimator!.delegate = self
    dataSource = self
  }

  internal enum BreakPoint : Int {
    case Earliest=0, FirstDistorted, Selected, LastDistorted, Latest
  }

  internal enum PointKind {
    case Linear, Anchored, FloatLeft, LinearMiddle, FloatRight
  }

  /**
  *  We use this shell class to let UIKit Dynamics to do the heavy lifting of the animation
  *  for our selected tick
  */
  internal class DynamicTick : NSObject, UIDynamicItem {
    var tick: CAShapeLayer
    var labels: [CATextLayer]
    var center: CGPoint {
      get {
        return CGPoint(x: tick.frame.midX, y: tick.frame.midY)
      }
      set {
        let w = tick.frame.width
        let h = tick.frame.height
        let xx = newValue.x - w/2.0
        let yy = newValue.y - h/2.0
        let newFrame = CGRect(x: xx, y: yy, width: w, height: h)
        tick.frame = newFrame
      }
    }
    var bounds: CGRect {
      get {
        return tick.bounds
      }
    }
    var transform: CGAffineTransform
    
    init(tick: CAShapeLayer, labels: [CATextLayer]) {
      self.tick = tick
      self.labels = labels
      self.transform = CGAffineTransformIdentity
      super.init()
    }
  }
  
  /**
  *  Used to map time to points and viceversa
  */
  struct TimeMappingPoint {
    var ti: NSTimeInterval
    var y: CGFloat
    var index: Int?

    func slopeTo(other: TimeMappingPoint) -> CGFloat {
      return (other.y - y)/CGFloat(other.ti - ti)
    }
    
    func projectTime(new_ti: NSTimeInterval, slope: CGFloat) -> TimeMappingPoint {
      return TimeMappingPoint(ti:new_ti, y:slope*CGFloat(new_ti-ti)+y, index:nil)
    }
    
    func projectOffset(new_y: CGFloat, slope: CGFloat) -> TimeMappingPoint {
      return TimeMappingPoint(ti: ti+NSTimeInterval((new_y-y)/slope), y: new_y, index:nil)
    }
  }
  
  var breakPoints = Dictionary<BreakPoint,TimeMappingPoint>()
  
  /// Delegate
  var delegate: JCMTimeSliderControlDelegate?
  
  /// Is in expanded form?
  var expanded: Bool {
    willSet {
      if expanded != newValue {
        expansionChangeNeeded = true
      }
    }
    
    didSet {
      if expansionChangeNeeded {
        expansionChangeNeeded = false
        if expanded {
          widthConstraint?.constant *= 2.0
        } else {
          widthConstraint?.constant *= 0.5
        }
        setNeedsLayout()
      }
    }
  }
  
  /// We manage the width of the control by changing this constraint
  @IBOutlet var widthConstraint: NSLayoutConstraint?

  /// The color of the labels
  var labelColor: UIColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)

  /// The color of the inactive ticks
  var inactiveTickColor: UIColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
  
  /// The color of the selected tick
  var selectedTickColor: UIColor = UIColor.whiteColor()
  
  var dataInsets: CGSize = CGSize(width: 0.0, height: 15.0)

  /// How many ticks around the selected one are shown linearly
  var linearExpansionRange: Int = 5
  
  /// How many pixels are the steps separated on the linear expansion
  var linearExpansionStep: CGFloat = 14.0
  
  /// The index of the last selected tick
  var lastSelectedIndex: Int? {
    didSet {
      setupMidPoints()
    }
  }
  
  /// Seconds from the time user lifts touch until the control auto-closes
  var secondsToClose: CGFloat? = 0.5
  
  /// Flag to allow the control to keep tracking even if user goes outside the frame
  var allowTrackOutsideControl: Bool = true
  
  /// The data source for this control
  var dataSource: JCMTimeSliderControlDataSource? {
    didSet {
      shouldUseTimeExpansion = (dataSource?.numberOfDates() > 2 * linearExpansionRange)
      setupEndPoints()
      setupSubViews()
    }
  }
  
  /// Layer for the ticks
  private var ticksLayer : CALayer?
  
  /// Layer for the labels
  private var labelsLayer : CALayer?
  
  private var centerTick : DynamicTick?
  
  /// Flag to determine whether to expand horizontally
  private var expansionChangeNeeded : Bool
  
  private var shouldUseTimeExpansion : Bool = false
  
  /// In case we are our own delegate, create an array as needed
  lazy private var dates: Array<NSDate> = {
    return Array<NSDate>()
  }()
  
  /// An animator to show a snapping effect on the selected tick
  var snapAnimUIDynamicAnimator: UIDynamicAnimator?
  
  /**
  Closes the control after a second
  */
  func closeLater() {
    if let lsi = lastSelectedIndex? {
      let date = dataSource!.dateAtIndex(lsi)
      delegate?.selectedDate?(date, index:lastSelectedIndex!, control:self)
    }

    if let stc = secondsToClose {
      dispatch_after(
        dispatch_time(
          DISPATCH_TIME_NOW,
          Int64(Double(stc) * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), {
          CATransaction.begin()
          CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
          self.expanded = false
          CATransaction.commit()
      })
    } else {
      self.expanded = false
    }
  }
  
  /**
  Every time the data source changes, we call this method to set the end points of the control
  and cache the dates and coordinates of the corresponding points.
  We also call this every time the geometry changes
  The invariant after this call is that breakPoints[.Earliest] and breakPoints[.Latest] will be
  set, either nil if the control is useable (more than 2 dates), or valid TimeMappingPoints
  */
  func setupEndPoints() {
    breakPoints.removeAll(keepCapacity: true)
    if let ds = dataSource {
      let numDates = self.dataSource!.numberOfDates()
      if numDates > 2 {
        let firstDate = self.dataSource!.dateAtIndex(0)
        let lastDate = self.dataSource!.dateAtIndex(numDates-1)
        let lowestCoord = dataInsets.height
        let highestCoord = frame.height - 2.0 * dataInsets.height
        breakPoints[.Earliest] = TimeMappingPoint(ti: firstDate.timeIntervalSinceReferenceDate, y: lowestCoord, index: 0)
        breakPoints[.Latest] = TimeMappingPoint(ti: lastDate.timeIntervalSinceReferenceDate, y: highestCoord, index: numDates-1)
      }
    }
  }
  
  /**
  Every time the selected index changes, we call this method to set the middle points of the control
  and cache the dates and coordinates.
  */
  func setupMidPoints() {
    breakPoints[.FirstDistorted] = nil
    breakPoints[.LastDistorted] = nil
    breakPoints[.Selected] = nil
    let earliest = breakPoints[.Earliest]
    let latest = breakPoints[.Latest]
    if (earliest == nil) || (latest == nil) {
      return
    }
    if let lsi = lastSelectedIndex {
      let linearSlope = earliest!.slopeTo(latest!)
      let midDate = dataSource!.dateAtIndex(lsi)
      breakPoints[.Selected] = earliest!.projectTime(midDate.timeIntervalSinceReferenceDate, slope: linearSlope)
      breakPoints[.Selected]!.index = lsi
      if shouldUseTimeExpansion {
        // Here the transfer function will be a broken line of 2 or 3 segments, depending to how
        // close we are to the edge.  The invariant is that the "center" segment, which has low
        // slope to allow precise time selection, always exists.  This segment goes between
        // .FirstDistorted and .LastDistorted
        let lastIndex = dataSource!.numberOfDates()-1
        let firstDistortedIndex = max(lsi - linearExpansionRange, 0)
        let lastDistortedIndex = min(lsi + linearExpansionRange, lastIndex)
        let mid = breakPoints[.Selected]
        let firstDistortedOffset = max(mid!.y - linearExpansionStep * CGFloat(lsi - firstDistortedIndex), breakPoints[.Earliest]!.y)
        let lastDistortedOffset = min(mid!.y - linearExpansionStep * CGFloat (lsi - lastDistortedIndex),breakPoints[.Latest]!.y)
        //println(firstDistortedIndex, lastDistortedIndex, firstDistortedOffset, lastDistortedOffset)
        breakPoints[.FirstDistorted] = TimeMappingPoint(ti: dataSource!.dateAtIndex(firstDistortedIndex).timeIntervalSinceReferenceDate, y: firstDistortedOffset, index: firstDistortedIndex)
        breakPoints[.LastDistorted] = TimeMappingPoint(ti: dataSource!.dateAtIndex(lastDistortedIndex).timeIntervalSinceReferenceDate, y: lastDistortedOffset, index: lastDistortedIndex)
      }
    }
  }
  
  /// The formatter for the short dates on the control
  class var shortDateFormatter : NSDateFormatter {
    struct Static {
      static let instance: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMM-yy"
        return dateFormatter
      }()
    }
    return Static.instance
  }

  /// The formatter for the long dates
  class var selectedDateFormatter : NSDateFormatter {
  struct Static {
    static let instance: NSDateFormatter = {
      let dateFormatter = NSDateFormatter()
      dateFormatter.dateFormat = "MM/dd/yy"
      return dateFormatter
      }()
    }
    return Static.instance
  }
  
  func setupSubViews() {
    createTicks()
    createLabels()
    updateTicksAndLabels()
  }

  override func beginTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool {
    expanded = true
    continueTrackingWithTouch(touch, withEvent: event)
    return true  // Track continuously
  }
  
  override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) -> Bool {
    if ((dataSource == nil) || (dataSource!.numberOfDates() < 2)) {
      closeLater()
      return false
    }
    
    let point = touch.locationInView(self)
    let global = touch.locationInView(self.superview)
    let inBounds = frame.contains(global)
    let offset = point.y
    let hypoDate = linearDateFrom(offset)
    lastSelectedIndex = findNearestDate(hypoDate)
    
    updateTicksAndLabels()
    
    delegate?.hoveredOverDate?(hypoDate, index: lastSelectedIndex!, control:self)
    
    let keepGoing = allowTrackOutsideControl ? true : inBounds
    if !keepGoing {
      closeLater()
    }
    return keepGoing
  }
  
  override func cancelTrackingWithEvent(event: UIEvent?) {
    super.cancelTrackingWithEvent(event)
    closeLater()
  }
  
  override func endTrackingWithTouch(touch: UITouch, withEvent event: UIEvent) {
    super.endTrackingWithTouch(touch, withEvent: event)
    
    if ((dataSource == nil) || (dataSource!.numberOfDates() < 2)) {
      return
    }
    
    // Prepare the snapping animation to the selected date
    let point = touch.locationInView(self)

    let snapPointY = distortedYOffsetFrom(dataSource!.dateAtIndex(lastSelectedIndex!), index: lastSelectedIndex!)
    if let sublayers = ticksLayer?.sublayers {
      let t = sublayers[lastSelectedIndex!] as CAShapeLayer
      let labels = labelsLayer!.sublayers as [CATextLayer]

      t.frame.offset(dx: 0, dy: linearExpansionStep)
      centerTick = DynamicTick(tick: t, labels:labels)
      let snapPoint = CGPoint(x: t.frame.midX,y: snapPointY)
      let snap = UISnapBehavior(item: centerTick!, snapToPoint: snapPoint)
      snap.damping = 0.1
      self.userInteractionEnabled = false
      snap.action = {
        println("Snapping")
      }
      snapAnimUIDynamicAnimator?.addBehavior(snap)
    } else {
      closeLater()
    }
  }
  
  func firstDate() -> NSDate? {
    return dataSource?.dateAtIndex(0)
  }
  
  func lastDate() -> NSDate? {
    return dataSource?.dateAtIndex(dataSource!.numberOfDates()-1)
  }
  
  /**
  Binary search for the index with the closest date to the one passed by parameter
  
  :param: searchItem the date we want to find in the data source
  
  :returns: the index at which we find the closest date available
  */
  func findNearestDate(searchItem :NSDate) -> Int {
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
  private func linearDateFrom(from: CGFloat) -> NSDate {
    let earliest = breakPoints[.Earliest]
    let latest = breakPoints[.Latest]
    let slope = earliest!.slopeTo(latest!)
    let temp = earliest!.projectOffset(from, slope: slope)
    return NSDate(timeIntervalSinceReferenceDate:temp.ti)
  }

  private func distortedDateFrom(from: CGFloat) -> NSDate {
    var leftPoint : TimeMappingPoint
    var rightPoint : TimeMappingPoint
    
    if from < breakPoints[.Earliest]!.y {
      println("<E")
      return NSDate(timeIntervalSinceReferenceDate:breakPoints[.Earliest]!.ti)
    }
    
    if let b = breakPoints[.FirstDistorted] {
      if from < b.y {
        println("E-FD")
        leftPoint = breakPoints[.Earliest]!
        let slope = leftPoint.slopeTo(b)
        let temp = leftPoint.projectOffset(from, slope: slope)
        return NSDate(timeIntervalSinceReferenceDate:temp.ti)
      }
    }
    
    if let b = breakPoints[.LastDistorted] {
      if from < b.y {
        println("FD-LD")
        let leftY = breakPoints[.FirstDistorted]!.y
        let leftIndex = breakPoints[.FirstDistorted]!.index!
        let rightY = b.y
        let rightIndex = b.index!
        let index = leftIndex + Int(round((from-leftY)/(rightY-leftY)*CGFloat(rightIndex-leftIndex)))
        println(index)
        return dataSource!.dateAtIndex(index)
      }
    }
    
    if from < breakPoints[.Latest]!.y {
      leftPoint = breakPoints[.Earliest]!
      if let b = breakPoints[.LastDistorted] {
        leftPoint = b
      }
      println(">>")
      let slope = leftPoint.slopeTo(breakPoints[.Latest]!)
      let temp = leftPoint.projectOffset(from, slope: slope)
      return NSDate(timeIntervalSinceReferenceDate:temp.ti)
    }
    
    return NSDate(timeIntervalSinceReferenceDate:breakPoints[.Latest]!.ti)
    //return linearDateFrom(from)
  }

  /**
  Linearly converts from a given date to the corresponding control offset
  
  :param: from is an NSDate that you want to represent on the control
  
  :returns: the offset in the control that corresponds linearly to that date
  */
  private func linearYOffsetFrom(from: NSDate) -> CGFloat {
    let earliest = breakPoints[.Earliest]
    let latest = breakPoints[.Latest]
    let slope = earliest!.slopeTo(latest!)
    let temp = earliest!.projectTime(from.timeIntervalSinceReferenceDate, slope: slope)
    return temp.y
  }
  
  /**
  Converts from a given date to the corresponding control offset, taking into account the
  last selected item, and a touch offset within the control
  
  :param: from is an NSDate that you want to represent on the control
  
  :returns: the offset in the control that corresponds to that date using the transform
  */
  private func distortedYOffsetFrom(from: NSDate, index: Int) -> CGFloat {
    var leftPoint : TimeMappingPoint
    var rightPoint : TimeMappingPoint

    switch indexToKind(index) {
    case .Anchored, .Linear:
      return linearYOffsetFrom(from)
    case .LinearMiddle:
      let baseY = breakPoints[.Selected]!.y
      let dist = index - lastSelectedIndex!
      return baseY + CGFloat(dist) * linearExpansionStep
    case .FloatLeft:
      leftPoint = breakPoints[.Earliest]!
      rightPoint = breakPoints[.FirstDistorted]!
    case .FloatRight:
      leftPoint = breakPoints[.LastDistorted]!
      rightPoint = breakPoints[.Latest]!
    }
    let slope = leftPoint.slopeTo(rightPoint)
    let temp = leftPoint.projectTime(from.timeIntervalSinceReferenceDate, slope: slope)
    return temp.y
  }
  
  /**
  Create a layer for the ticks, with sublayers representing each tick
  */
  private func createTicks() {

    assert(dataSource != nil, kNoDataSourceInconsistency)
    let lastIndex = dataSource!.numberOfDates()
    
    if ticksLayer != nil {
      ticksLayer!.removeFromSuperlayer()
    }

    ticksLayer = CALayer()
    layer.addSublayer(ticksLayer!)

    ticksLayer!.masksToBounds = true
    ticksLayer!.position = CGPointZero
    
    for i in 0...lastIndex-1 {
      let aTick = CAShapeLayer()
      aTick.anchorPoint = CGPointZero
      ticksLayer!.addSublayer(aTick)

      aTick.frame = CGRect(origin: CGPoint.zeroPoint,size: CGSize(width: frame.width,height: 2.0))
      aTick.fillColor = UIColor.clearColor().CGColor
      aTick.strokeColor = inactiveTickColor.CGColor
      aTick.lineWidth = 1.0
      aTick.lineCap = kCALineCapRound!
      aTick.opacity = 1.0

      let path = UIBezierPath()
      path.moveToPoint(CGPoint(x: frame.width * 0.66,y: 1.0))
      path.addLineToPoint(CGPoint(x: frame.width, y: 1.0))
      aTick.path = path.CGPath
    }
  }
  
  /**
  Utility to map a given index to the kind of tick that we should display
  
  :param: index the index of the tick
  
  :returns: the kind of point we should show
  */
  private func indexToKind(index: Int) -> PointKind {
    if expanded && shouldUseTimeExpansion {
      if let lsi = lastSelectedIndex {
        switch index {
        case 0,lsi,numberOfDates():
          return .Anchored
        default:
          if (index >= breakPoints[.FirstDistorted]?.index) && (index <= breakPoints[.LastDistorted]?.index) {
            return .LinearMiddle
          } else if (index < breakPoints[.FirstDistorted]?.index) {
            return .FloatLeft
          } else {
            return .FloatRight
          }
        }
      }
    }
    return .Linear
  }

  /**
  Create the labels that will show dates
  */
  private func createLabels() {
    assert(dataSource != nil, kNoDataSourceInconsistency)
    let lastIndex = dataSource!.numberOfDates()

    if labelsLayer != nil {
      labelsLayer!.removeFromSuperlayer()
    }
    
    labelsLayer = CALayer()
    layer.addSublayer(labelsLayer!)
    
    labelsLayer!.anchorPoint = CGPointZero
    labelsLayer!.masksToBounds = false
    labelsLayer!.position = CGPointZero
    
    let a : Int = BreakPoint.Earliest.rawValue
    let b = BreakPoint.Latest.rawValue
    let font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
    let height = font.ascender - font.descender
    for i in a...b {
      let aLabel = CATextLayer()
      aLabel.anchorPoint = CGPointZero
      labelsLayer!.addSublayer(aLabel)

      aLabel.frame = CGRect(x: 0.0, y: 0.0, width: frame.width * 1.5, height: height)
      aLabel.fontSize = UIFont.smallSystemFontSize()
      aLabel.font = font
      aLabel.opacity = 0.0
      aLabel.string = ""
    }

  }
  
  /**
  Set the ticks to the desired position
  */
  func updateTicksAndLabels() {
    assert(dataSource != nil, kNoDataSourceInconsistency)
    let font = UIFont.systemFontOfSize(UIFont.smallSystemFontSize())
    let fontOffset = -(font.xHeight / 2.0 - font.descender)
    let lastIndex = dataSource!.numberOfDates()
    if let sublayers = ticksLayer?.sublayers {
      assert(lastIndex == sublayers.count, kNoWrongNumberOfLayersInconsistency)
      
      // Pick the transform for the selected tick
      let selectedTransform = CATransform3DConcat(CATransform3DMakeTranslation(-15.0, 0.0, 0.0), CATransform3DMakeScale(2.0, 2.0, 1.0))
      
      // Start animating as a single transaction
      CATransaction.begin()
      CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
      
      // Assume labels won't be visible, to start with
      for label in labelsLayer!.sublayers as [CATextLayer] {
        label.opacity = 0.0
        label.foregroundColor = labelColor.CGColor
      }
      
      // Process each tick
      for i in 0...lastIndex-1 {
        let tick = sublayers[i] as CAShapeLayer
        tick.lineWidth = 1.0
        tick.transform = CATransform3DIdentity
        
        var offset = distortedYOffsetFrom(dataSource!.dateAtIndex(i), index: i)
        switch indexToKind(i) {
        case .LinearMiddle:
          if (offset < breakPoints[.Earliest]!.y) ||
            (offset > breakPoints[.Latest]!.y) {
              tick.strokeColor = UIColor.clearColor().CGColor
          } else {
            let indexDifference = abs(lastSelectedIndex! - i)
            tick.strokeColor = selectedTickColor.colorWithAlphaComponent(1.0-0.5*CGFloat(indexDifference)/CGFloat(linearExpansionRange)).CGColor
          }
        case .FloatRight, .FloatLeft:
          tick.strokeColor = inactiveTickColor.CGColor
        case .Anchored:
          tick.strokeColor = inactiveTickColor.CGColor
        case .Linear:
          tick.strokeColor = inactiveTickColor.CGColor
        }
        
        
        // Always show the labels for the first date
        if (expanded && (i==0) && (lastSelectedIndex? != 0)) {
          let label = labelsLayer?.sublayers[BreakPoint.Earliest.rawValue] as CATextLayer
          label.position = CGPoint(x: 0, y: offset + fontOffset)
          label.opacity = 1.0
          let date = dataSource!.dateAtIndex(i)
          label.string = JCMTimeSliderControl.shortDateFormatter.stringFromDate(date)
        }
        
        // Always show the label for the last date
        if (expanded && (i == lastIndex-1) && (lastSelectedIndex? != lastIndex-1)) {
          let label = labelsLayer?.sublayers[BreakPoint.Latest.rawValue] as CATextLayer
          label.position = CGPoint(x: 0, y: offset + fontOffset)
          let date = dataSource!.dateAtIndex(i)
          label.string = JCMTimeSliderControl.shortDateFormatter.stringFromDate(date)
          label.opacity = 1.0
        }
        
        // Find out if this tick is a "normal" one (outside the expanded range), and process it
        // differently if it is not
        if let lsi = lastSelectedIndex {
          let indexDifference = abs(lsi - i)
          if (indexDifference < linearExpansionRange) {
            if (i == lastSelectedIndex) {
              
              // This is the selected tick.  Draw it, plus its label.
              tick.transform = selectedTransform
              tick.strokeColor = selectedTickColor.CGColor
              tick.lineWidth = 3.0
              
              if expanded {
                let label = labelsLayer?.sublayers[BreakPoint.Selected.rawValue] as CATextLayer
                label.position = CGPoint(x: 0, y: offset + fontOffset)
                label.opacity = 1.0
                let date = dataSource!.dateAtIndex(i)
                label.string = JCMTimeSliderControl.selectedDateFormatter.stringFromDate(date)
              }

            } else {
              // Draw the accessory ticks that visually highlight the expanded range
              if (expanded) {
                tick.transform = CATransform3DMakeTranslation(-2.0*CGFloat(linearExpansionRange-indexDifference), 0.0, 0.0)
              }
              
              if expanded && (indexDifference == linearExpansionRange - 1) {
                let labelID = (i > lastSelectedIndex) ? BreakPoint.LastDistorted : BreakPoint.FirstDistorted
                let label = labelsLayer?.sublayers[labelID.rawValue] as CATextLayer
                
                label.opacity = 0.3
                label.position = CGPoint(x: 0, y: offset + fontOffset)

                let date = dataSource!.dateAtIndex(i)
                label.string = JCMTimeSliderControl.selectedDateFormatter.stringFromDate(date)
              }
            }
          }
        }
        
        tick.position = CGPoint(x: (expanded ? 36.0 : 0.0), y: offset)
        
        // Hide any labels out of bounds
        for label in labelsLayer!.sublayers as [CATextLayer] {
          if (label.position.y < breakPoints[.Earliest]!.y) ||
             (label.position.y > breakPoints[.Latest]!.y) {
            label.opacity = 0.0
          }
        }
      }
      CATransaction.commit()
    }
    setNeedsDisplay()
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    setupEndPoints()
    setupMidPoints()
    ticksLayer?.frame = bounds
    updateTicksAndLabels()
    labelsLayer?.frame = bounds
  }

  func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
    if animator == snapAnimUIDynamicAnimator? {
      println("Snapped")
      animator.removeAllBehaviors()
      self.userInteractionEnabled = true
      self.expanded = false
    }
  }
  // MARK - Methods to be our own data source

  func numberOfDates() -> Int {
    return dates.count
  }
  
  func dateAtIndex(index: Int) -> NSDate {
    return dates[index]
  }
  
  override func prepareForInterfaceBuilder() {
    let twoYearsAgo=NSDate(timeIntervalSinceNow: -2*365*24*60*60)
    let now = NSDate(timeIntervalSinceNow: 0)
    let amount = Int(arc4random_uniform(25))
    var a = Array<NSDate>()
    let diff = now.timeIntervalSinceDate(twoYearsAgo)
    for i in 1...amount {
      let randomNumber = arc4random_uniform(UINT32_MAX)
      let randomTimeInterval = diff * Double(randomNumber) / Double(UINT32_MAX)
      a.append(NSDate(timeInterval: randomTimeInterval, sinceDate: twoYearsAgo))
    }
    a.sort { (d1, d2) -> Bool in
      return d1.compare(d2) == NSComparisonResult.OrderedAscending
    }
    self.dates = a
  }

}

internal let kNoDataSourceInconsistency : String = "Must have a data source"
internal let kNoWrongNumberOfLayersInconsistency : String = "Inconsistent number of layers"

