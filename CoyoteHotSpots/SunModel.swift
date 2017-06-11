// Copyright © 2016-2017 High Point Studios LLC. All rights reserved.

import Foundation
import CoreLocation

class SunModel: NSObject
{
   public fileprivate(set) var timeZone: TimeZone = TimeZone.autoupdatingCurrent
   public fileprivate(set) var latitude: Double = 0.0
   public fileprivate(set) var longitude: Double = 0.0
   public fileprivate(set) var date: Date = Date()
   public fileprivate(set) var sunrise: Date?
   public fileprivate(set) var sunset: Date?
   public fileprivate(set) var civilSunrise: Date?
   public fileprivate(set) var civilSunset: Date?
   public fileprivate(set) var nauticalSunrise: Date?
   public fileprivate(set) var nauticalSunset: Date?
   public fileprivate(set) var astronomicalSunrise: Date?
   public fileprivate(set) var astronomicalSunset: Date?

   var utcTimezone: TimeZone
   var calendar: Calendar

   override init()
   {
      utcTimezone = TimeZone( identifier: "UTC" )!
      calendar = Calendar( identifier: Calendar.Identifier.gregorian )
      super.init()
   }

   /// Whether the location specified by the `latitude` and `longitude` is in daytime on `date`
   public var isDaytime: Bool
   {
      let beginningOfDay = sunrise?.timeIntervalSince1970
      let endOfDay = sunset?.timeIntervalSince1970
      let currentTime = self.date.timeIntervalSince1970

      return currentTime >= beginningOfDay && currentTime <= endOfDay
   }

   /// Whether the location specified by the `latitude` and `longitude` is in nighttime on `date`
   public var isNighttime: Bool
   {
      return !isDaytime
   }

   public func set( date: Date = Date(), withTimeZone timeZone: TimeZone = TimeZone.autoupdatingCurrent, latitude: Double, longitude: Double )
   {
      self.date = date
      self.timeZone = timeZone
      self.latitude = latitude
      self.longitude = longitude

      calculate()
   }

   public func set( date: Date = Date(), withTimeZone timeZone: TimeZone = TimeZone.autoupdatingCurrent, location: CLLocation? )
   {
      self.set( date: date, withTimeZone: timeZone, latitude: location!.coordinate.latitude, longitude: location!.coordinate.longitude )
   }

   // MARK: - Public functions

   /// Sets all of the Sun object's sunrise / sunset variables, if possible.
   /// - Note: Can return `nil` objects if sunrise / sunset does not occur on that day.
   public func calculate()
   {
      // Get the day of the year
      calendar.timeZone = utcTimezone
      guard let dayInt = calendar.ordinality( of: .day, in: .year, for: date ) else { return }
      let day = Double( dayInt )

      sunrise = calculate( .sunrise, forDate: date, andZenith: .official, day: day )
      sunset = calculate( .sunset, forDate: date, andZenith: .official, day: day )
      civilSunrise = calculate( .sunrise, forDate: date, andZenith: .civil, day: day )
      civilSunset = calculate( .sunset, forDate: date, andZenith: .civil, day: day )
      nauticalSunrise = calculate( .sunrise, forDate: date, andZenith: .nautical, day: day )
      nauticalSunset = calculate( .sunset, forDate: date, andZenith: .nautical, day: day )
      astronomicalSunrise = calculate( .sunrise, forDate: date, andZenith: .astronimical, day: day )
      astronomicalSunset = calculate( .sunset, forDate: date, andZenith: .astronimical, day: day )
   }

   // MARK: - Private functions

   fileprivate enum SunriseSunset
   {
      case sunrise
      case sunset
   }

   // Used for generating several of the possible sunrise / sunset times
   fileprivate enum Zenith: Double
   {
      case official = 90.83
      case civil = 96.0
      case nautical = 102.0
      case astronimical = 108.0
   }

   fileprivate func calculate( _ sunriseSunset: SunriseSunset, forDate date: Date, andZenith zenith: Zenith, day: Double ) -> Date?
   {
      // Get the day of the year
      //      calendar.timeZone = utcTimezone
      //      guard let dayInt = calendar.ordinality( of: .day, in: .year, for: date ) else { return nil }
      //      let day = Double( dayInt )

      // Convert longitude to hour value and calculate an approx. time
      let lngHour = longitude / 15

      let hourTime: Double = sunriseSunset == .sunrise ? 6 : 18
      let t = day + ( ( hourTime - lngHour ) / 24 )

      // Calculate the sun's mean anomaly
      let M = ( 0.9856 * t ) - 3.289

      // Calculate the sun's true longitude
      let subexpression1 = 1.916 * sin( M.degreesToRadians )
      let subexpression2 = 0.020 * sin( 2 * M.degreesToRadians )
      var L = M + subexpression1 + subexpression2 + 282.634

      // Normalise L into [0, 360] range
      L = L.normalize( maximum: 360 )

      // Calculate the Sun's right ascension
      var RA = atan( 0.91764 * tan( L.degreesToRadians ) ).radiansToDegrees

      // Normalise RA into [0, 360] range
      RA = RA.normalize( maximum: 360 )

      // Right ascension value needs to be in the same quadrant as L...
      let Lquadrant = floor( L / 90 ) * 90
      let RAquadrant = floor( RA / 90 ) * 90
      RA = RA + ( Lquadrant - RAquadrant )

      // Convert RA into hours
      RA = RA / 15

      // Calculate Sun's declination
      let sinDec = 0.39782 * sin( L.degreesToRadians )
      let cosDec = cos( asin( sinDec ) )

      // Calculate the Sun's local hour angle
      let cosH = ( cos( zenith.rawValue.degreesToRadians ) - ( sinDec * sin( latitude.degreesToRadians ) ) ) / ( cosDec * cos( latitude.degreesToRadians ) )

      // No sunrise
      guard cosH < 1 else { return nil }

      // No sunset
      guard cosH > -1 else { return nil }

      // Finish calculating H and convert into hours
      let tempH = sunriseSunset == .sunrise ? 360 - acos( cosH ).radiansToDegrees : acos( cosH ).radiansToDegrees
      let H = tempH / 15.0

      // Calculate local mean time of rising
      let T = H + RA - ( 0.06571 * t ) - 6.622

      // Adjust time back to UTC
      var UT = T - lngHour

      // Normalise UT into [0, 24] range
      UT = UT.normalize( maximum: 24 )

      // Convert UT value to local time zone of lat/long provided
      var localT = UT + ( Double( timeZone.secondsFromGMT( for: date ) ) / 3600.0 )

      // As applying the offset can push localT above 24 or below 0, we need to normalise
      localT = localT.normalize( maximum: 24)

      // Calculate all of the sunrise's / sunset's date components
      let hour = floor( localT )
      let minute = floor( ( localT - hour ) * 60.0 )
      let second = ( ( ( localT - hour ) * 60 ) - minute ) * 60.0

      var components = calendar.dateComponents( [.day, .month, .year], from: date )
      components.hour = Int( hour )
      components.minute = Int( minute )
      components.second = Int( second )

      calendar.timeZone = timeZone
      return calendar.date( from: components )
   }
}

