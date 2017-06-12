// Copyright © 2017 Bradford Holcombe. All rights reserved.

import Foundation

/** Lat/Lon tuple type */
public typealias LatLon = ( latitude: Double, longitude: Double )

class Fix
{
   var latLon: LatLon = ( 40.0, -75.0 )
   var date = Date()
   var isDaytime = false
   var previousSunset: Date?

  init( dateString: String, lat: Double = 40.0, lon: Double = -75.0 )
   {
      let formatterZ = DateFormatter()
      formatterZ.dateFormat = "yyyy/MM/dd HH:mm:ss ZZZ"
      date = formatterZ.date( from: dateString )!
      latLon = ( lat, lon )

      let sunModel = SunModel()
      let cal = Calendar.current
      var oneDay = DateComponents()
      oneDay.day = 1
      var minusOneDay = DateComponents()
      minusOneDay.day = -1

         sunModel.set( date: date, latLon: latLon )
         isDaytime = sunModel.isDaytime
         let dSunset = sunModel.sunset
         let previousDay = (cal as NSCalendar).date( byAdding: minusOneDay, to: date, options: NSCalendar.Options( rawValue: 0 ) )!
         sunModel.set( date: previousDay, latLon: latLon )
         let pSunset = sunModel.sunset
         let nextDay = (cal as NSCalendar).date( byAdding: oneDay, to: date, options: NSCalendar.Options( rawValue: 0 ) )!
         sunModel.set( date: nextDay, latLon: latLon )
         let nSunset = sunModel.sunset

         if date < dSunset!
         {
            previousSunset = pSunset
         }
         else if date < nSunset!
         {
            previousSunset = dSunset
         }
         else
         {
            previousSunset = nSunset
         }
      
   }
}

