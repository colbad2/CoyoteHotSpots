// Copyright © 2017 Bradford Holcombe. All rights reserved.

import Foundation

class Segmenter
{
   // assumes fixes are ordered by date
   func segment( fixes: [ Fix ] ) -> [ Night ]
   {
      let sunModel = SunModel()
      let cal = Calendar.current
      var oneDay = DateComponents()
      oneDay.day = 1
      for fix in fixes
      {
         sunModel.set( date: fix.date, latLon: fix.latLon, zenith: .official )
         fix.isBeforeSunrise = sunModel.sunrise != nil && fix.date < sunModel.sunrise!
         fix.isDaytime = sunModel.isDaytime
         fix.isAfterSunset = sunModel.sunset != nil && fix.date > sunModel.sunset!
         fix.midnight = cal.startOfDay( for: fix.date )
         if fix.isAfterSunset
         {
            fix.midnight = (cal as NSCalendar).date( byAdding: oneDay, to: fix.midnight!, options: NSCalendar.Options( rawValue: 0 ) )
         }
      }
      
      var nights = [ Night ]()
      var currentNight: Night?
      var currentMidnight: Date?
      for fix in fixes
      {
         if fix.isDaytime
         {
            if currentNight != nil
            {
               nights.append( currentNight! )
               currentNight = nil
            }
         }
         else
         {
            if currentMidnight == nil
            {
               currentMidnight = fix.midnight
            }
            if fix.midnight != currentMidnight
            {
               nights.append( currentNight! )
               currentNight = nil
            }
            if currentNight == nil
            {
               currentNight = Night()
               currentNight?.midnight = fix.midnight
               nights.append( currentNight! )
            }
            currentNight!.fixes.append( fix )
         }
      }

      return nights
   }
}
