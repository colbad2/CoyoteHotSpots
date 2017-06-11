// Copyright © 2017 Bradford Holcombe. All rights reserved.

import XCTest

class SegmenterTests: XCTestCase
{
   var segmenter: Segmenter?
   var formatter: DateFormatter?

    override func setUp()
    {
      segmenter = Segmenter()
      formatter = DateFormatter()
      formatter!.dateFormat = "yyyy/MM/dd HH:mm"
    }

   func testEmptyFixList()
   {
      let fixes = [ Fix ]()
      let nights = segmenter!.segment( fixes: fixes )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 0 )
   }

   func testSingleFixList()
   {
      let fix = Fix()
      fix.date = formatter!.date( from: "2016/10/08 22:31" )!
      let fixes = [ fix ]
      let nights = segmenter!.segment( fixes: fixes )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 1 )
      XCTAssertEqual( nights.first!.midnight, fix.midnight )
      XCTAssertEqual( fix.midnight, formatter!.date( from: "2016/10/08 00:00" )! )
   }

   func testTwoFixList()
   {
      let fix = Fix()
      fix.date = formatter!.date( from: "2016/10/08 22:31" )!
      let fix2 = Fix()
      fix2.date = formatter!.date( from: "2016/10/08 22:32" )!
      let fixes = [ fix, fix2 ]
      let nights = segmenter!.segment( fixes: fixes )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 1 )
      XCTAssertEqual( nights.first!.midnight, fix.midnight )
      XCTAssertEqual( fix.midnight, formatter!.date( from: "2016/10/08 00:00" )! )
      XCTAssertEqual( nights.first!.midnight, fix2.midnight )
      XCTAssertEqual( fix2.midnight, formatter!.date( from: "2016/10/08 00:00" )! )
   }

   func testTwoDayFixList()
   {
      let fix = Fix()
      fix.date = formatter!.date( from: "2016/10/08 22:31" )!
      let fix2 = Fix()
      fix2.date = formatter!.date( from: "2016/10/18 22:32" )!
      let fixes = [ fix, fix2 ]
      let nights = segmenter!.segment( fixes: fixes )

      XCTAssertNotNil( nights )
      XCTAssertEqual( nights.count, 2 )
      XCTAssertEqual( nights.first!.midnight, fix.midnight )
      XCTAssertEqual( fix.midnight, formatter!.date( from: "2016/10/08 00:00" )! )
      XCTAssertEqual( nights.first!.midnight, fix2.midnight )
      XCTAssertEqual( fix2.midnight, formatter!.date( from: "2016/10/18 00:00" )! )
   }
}
