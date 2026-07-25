import Foundation

// MARK: - Venue Time Zone

/// Maps fixture venues to IANA time zones for correct kickoff parsing and display.
enum VenueTimeZone {
    static func timeZone(for venue: [String: JSONValue]?) -> TimeZone {
        let country = venue?.string(for: ["countryName"])?.lowercased() ?? ""
        let city = venue?.string(for: ["city"])?.lowercased() ?? ""

        if country.contains("sri lanka") {
            return zone("Asia/Colombo")
        }
        if country.contains("india") {
            return zone("Asia/Kolkata")
        }
        if country.contains("pakistan") {
            return zone("Asia/Karachi")
        }
        if country.contains("bangladesh") {
            return zone("Asia/Dhaka")
        }
        if country.contains("australia") {
            if city.contains("perth") { return zone("Australia/Perth") }
            if city.contains("adelaide") { return zone("Australia/Adelaide") }
            if city.contains("brisbane") { return zone("Australia/Brisbane") }
            if city.contains("hobart") { return zone("Australia/Hobart") }
            return zone("Australia/Sydney")
        }
        if country.contains("new zealand") {
            return zone("Pacific/Auckland")
        }
        if country.contains("england") || country.contains("united kingdom") || country.contains("wales") {
            return zone("Europe/London")
        }
        if country.contains("northern ireland") || country.contains("ireland") {
            return zone("Europe/Dublin")
        }
        if country.contains("south africa") {
            return zone("Africa/Johannesburg")
        }
        if country.contains("united arab emirates") || country.contains("uae") {
            return zone("Asia/Dubai")
        }
        if country.contains("united states") || country.contains("usa") {
            return zone("America/New_York")
        }
        if country.contains("west indies") || country.contains("caribbean") {
            return zone("America/Port_of_Spain")
        }

        return .current
    }

    private static func zone(_ identifier: String) -> TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }
}
