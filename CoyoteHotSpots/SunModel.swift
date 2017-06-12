// Copyright © 2016-2017 High Point Studios LLC. All rights reserved.

import Foundation

extension Double
{
   var degreesToRadians: Double { return ( self * Double.pi ) / 180.0 }
   var radiansToDegrees: Double { return ( self * 180.0 ) / Double.pi }

   /**
    Shift the Double value to the range [0, maximum) by repeated addition or subtraction of maximum.
    */
   func normalize( maximum: Double ) -> Double
   {
      var value = self
      while value < 0 { value += maximum }
      while value >= maximum { value -= maximum }

      return value
   }
}

// Used for generating several of the possible sunrise / sunset times
public enum Zenith: Double
{
   case official = 90.83
   case civil = 96.0
   case nautical = 102.0
   case astronomical = 108.0
}

class SunModel: NSObject
{
   let SECONDS_PER_DAY = 60.0 * 60.0 * 24.0
   public fileprivate(set) var latitude: Double = 0.0
   public fileprivate(set) var longitude: Double = 0.0
   public fileprivate(set) var date: Date = Date()
   public fileprivate(set) var sunrise: Date?
   public fileprivate(set) var sunset: Date?

   var calendar = Calendar( identifier: Calendar.Identifier.gregorian )

   override init()
   {
      calendar.timeZone = TimeZone( identifier: "UTC" )!
      super.init()
   }

   /// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
   public var isDaytime: Bool
   {
      if sunrise == nil { return false }
      let beginningOfDay = sunrise!.timeIntervalSince1970
      if sunset == nil { return true }
      let endOfDay = sunset!.timeIntervalSince1970
      let currentTime = date.timeIntervalSince1970

      return currentTime >= beginningOfDay && currentTime <= endOfDay
   }

   /// Sets all of the Sun object's sunrise / sunset variables, if possible.
   /// - Note: Can return `nil` objects if sunrise / sunset does not occur on that day.
   public func set( date date_: Date, latLon: LatLon, zenith: Zenith = .official )
   {
      date = date_
      latitude = latLon.latitude
      longitude = latLon.longitude

      // Get the day of the year
      guard let dayInt = calendar.ordinality( of: .day, in: .year, for: date ) else { return }
      let day = Double( dayInt )

      switch zenith
      {
      case .astronomical:
         sunrise = calculate( .sunrise, forDate: date, andZenith: .astronomical, day: day )
         sunset = calculate( .sunset, forDate: date, andZenith: .astronomical, day: day )
      case .civil:
         sunrise = calculate( .sunrise, forDate: date, andZenith: .civil, day: day )
         sunset = calculate( .sunset, forDate: date, andZenith: .civil, day: day )
      case .nautical:
         sunrise = calculate( .sunrise, forDate: date, andZenith: .nautical, day: day )
         sunset = calculate( .sunset, forDate: date, andZenith: .nautical, day: day )
      case .official:
         sunrise = calculate( .sunrise, forDate: date, andZenith: .official, day: day )
         sunset = calculate( .sunset, forDate: date, andZenith: .official, day: day )
      }
   }

   // MARK: - Private functions

   fileprivate enum SunriseSunset: Double
   {
      case sunrise = 6.0
      case sunset = 18.0
   }

   fileprivate func calculate( _ sunriseSunset: SunriseSunset, forDate date: Date, andZenith zenith: Zenith, day: Double ) -> Date?
   {
      // calculate an approximate time
      let longitudeHour = longitude / 15.0
      let t = day + ( ( sunriseSunset.rawValue - longitudeHour ) / 24.0 )

      // sun's mean anomaly (degrees)
      let M = ( ( 0.98560028 * t ) - 3.289 ).normalize( maximum: 360.0 )

      // equation of the center
      // C = 1.9148sin(M)+0.0200sin(2M)+0.0003sin(3M)
      let C = 1.9148 * sin( M.degreesToRadians ) + 0.02 * sin( 2 * M.degreesToRadians ) + 0.0003 * sin( 3 * M.degreesToRadians )

      // sun's true longitude
      // lambda = ( M + C + 180 + 102.9372 ) mod 360
      let L = ( M + C + 180.0 + 102.9372 ).normalize( maximum: 360.0 )

      // Sun's right ascension
      var RA = atan( 0.91764 * tan( L.degreesToRadians ) ).radiansToDegrees.normalize( maximum: 360.0 )
      let Lquadrant = floor( L / 90.0 ) * 90.0 // same quadrant as L...
      let RAquadrant = floor( RA / 90.0 ) * 90.0
      RA = RA + ( Lquadrant - RAquadrant )
      RA = RA / 15.0 // convert to hours

      // Sun's declination
      // sin(delta) = sin(lambda) sin(23.44degrees)
      let sinDec = 0.39782 * sin( L.degreesToRadians )
      let cosDec = cos( asin( sinDec ) )

      // Sun's local hour
      let cosH = ( cos( zenith.rawValue.degreesToRadians ) - ( sinDec * sin( latitude.degreesToRadians ) ) ) / ( cosDec * cos( latitude.degreesToRadians ) )
      guard cosH < 1 else { return nil } // No sunrise
      guard cosH > -1 else { return nil } // No sunset
      let hourAngle = acos( cosH ).radiansToDegrees
      let tempH = sunriseSunset == .sunrise ? 360.0 - hourAngle : hourAngle
      let H = tempH / 15.0 // convert into hours

      // local mean time of rising
      let T = H + RA - ( 0.06571 * t ) - 6.622

      // Adjust time back to UTC
      var UT = T - longitudeHour
      UT = UT.normalize( maximum: 24.0 )

      // Calculate all of the sunrise's / sunset's date components
      let hour = floor( UT )
      let minute = floor( ( UT - hour ) * 60.0 )
      let second = ( ( ( UT - hour ) * 60.0 ) - minute ) * 60.0

      var components = calendar.dateComponents( [ .day, .month, .year ], from: date )
      components.hour = Int( hour )
      components.minute = Int( minute )
      components.second = Int( second )

      return calendar.date( from: components )
   }
}


