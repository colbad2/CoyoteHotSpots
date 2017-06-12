// Copyright © 2017 Bradford Holcombe. All rights reserved.

import XCTest

class SegmenterTests: XCTestCase
{
   var segmenter: Segmenter?
   var formatterZ = DateFormatter()

    override func setUp()
    {
      segmenter = Segmenter()
      formatterZ.dateFormat = "yyyy/MM/dd HH:mm:ss ZZZ"
    }

   func testEmptyFixList()
   {
      let nights = segmenter!.segment( fixes: [ Fix ]() )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 0 )
   }

   func testSingleFixList()
   {
      let fix = Fix( dateString: "2016/10/08 22:31:00 -0400" )
      let nights = segmenter!.segment( fixes: [ fix ] )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 1 )
      XCTAssertEqual( nights.first!.previousSunset, fix.previousSunset )
      XCTAssertEqual( fix.previousSunset, formatterZ.date( from: "2016/10/08 07:14:28 +0000" )! )
   }

   func testTwoFixList()
   {
      let fix = Fix( dateString: "2016/10/08 22:31:00 -0400" )
      let fix2 = Fix( dateString: "2016/10/08 22:32:00 -0400" )
      let nights = segmenter!.segment( fixes: [ fix, fix2 ] )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 1 )
      XCTAssertEqual( nights.first!.previousSunset, fix.previousSunset )
      XCTAssertEqual( fix.previousSunset, formatterZ.date( from: "2016/10/08 07:14:28 +0000" )! )
      XCTAssertEqual( nights.first!.previousSunset, fix2.previousSunset )
      XCTAssertEqual( fix2.previousSunset, formatterZ.date( from: "2016/10/08 07:14:28 +0000" )! )
   }

   func testFixMidnights()
   {
      compareMidnight( date: "2016/10/08 00:00:00 -0400", previousSunset: "2016/10/07 22:28:37 +0000" )
      compareMidnight( date: "2016/10/08 01:00:00 -0400", previousSunset: "2016/10/07 22:28:37 +0000" )
      compareMidnight( date: "2016/10/08 12:00:00 -0400", previousSunset: "2016/10/07 22:28:37 +0000" )
      compareMidnight( date: "2016/10/08 22:00:00 -0400", previousSunset: "2016/10/08 22:26:48 +0000" )
      compareMidnight( date: "2016/10/08 23:00:00 -0400", previousSunset: "2016/10/08 22:26:48 +0000" )
   }

   func compareMidnight( date: String, previousSunset: String )
   {
      let fix = Fix( dateString: date )
      _ = segmenter!.segment( fixes: [ fix ] )
      let p = formatterZ.date( from: previousSunset )!
      XCTAssertEqual( fix.previousSunset, p )
   }

   func testTwoDayFixList()
   {
      let fix = Fix( dateString: "2016/10/08 22:31:00 -0400" )
      let fix2 = Fix( dateString: "2016/10/18 22:32:00 -0400" )
      let nights = segmenter!.segment( fixes: [ fix, fix2 ] )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 2 )
      XCTAssertEqual( nights[ 0 ].previousSunset, fix.previousSunset )
      XCTAssertEqual( fix.previousSunset, formatterZ.date( from: "2016/10/08 07:14:28 +0000" )! )
      XCTAssertEqual( nights[ 1 ].previousSunset, fix2.previousSunset )
      XCTAssertEqual( fix2.previousSunset, formatterZ.date( from: "2016/10/18 07:17:43 +0000" )! )
   }
}
