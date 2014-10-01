JCMTimeSlider
=============

This is an iOS control to navigate a timeline with large number of data points (dates)

![JCMTimeSlider in action](http://jcmendez.github.io/JCMTimeSlider/images/sample.gif)

Usage
=====

The code below gives an idea of what it is needed to use the control.  The regular datasource/delegate pattern is used.

The data source needs to implement 2 functions: `numberOfDates()` and `dateAtIndex()`.  The latter must guarantee the dates are sorted in ascending order.

    class SampleData: JCMTimeSliderControlDataSource {
      func numberOfDates() -> Int {
        return data!.count
      }

      func dateAtIndex(index: Int) -> NSDate {
        return data![index]
      }
    }


The delegate can optionally implement `hoveredOverDate` and `selectedDate` 

    class ViewController: UIViewController, JCMTimeSliderControlDelegate {

      @IBOutlet var timeControl1: JCMTimeSliderControl?

      override func viewDidLoad() {
        super.viewDidLoad()
        timeControl1?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.4)
        timeControl1?.dataSource = your_data_source
        timeControl1?.delegate = self
        timeControl1?.tag = 1
      }

      func hoveredOverDate(date: NSDate, index: Int, control: JCMTimeSliderControl) {
        println("Hovered over control: \(control.tag) -> Date: \(date), loc: \(index)")
      }

      func selectedDate(date: NSDate, index: Int, control: JCMTimeSliderControl) {
        println("Selected control: \(control.tag) -> Date: \(date), loc: \(index)")
      }

    }






To Do
=====

Lots of debugging required.  This is a very early implementation.  