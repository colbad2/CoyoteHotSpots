// Copyright © 2017 Bradford Holcombe. All rights reserved.

import Foundation

/** Lat/Lon tuple type */
public typealias LatLon = ( latitude: Double, longitude: Double )

class Fix
{
   var latLon: LatLon = ( -200.0, -200.0 )
   var date = Date()
   var isBeforeSunrise = false
   var isDaytime = false
   var isAfterSunset = false
   var midnight: Date?
}

