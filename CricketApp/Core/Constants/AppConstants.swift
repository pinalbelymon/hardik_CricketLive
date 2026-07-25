import Foundation

// MARK: - App Constants

/// Centralized constants for API hosts, product metadata, and remote config defaults.
enum AppConstants {
    static let appName = "CricPlus"
    static let appId = "id6793374045"
    static let bundleIdentifier = "com.vivekmalani.cricketapp"
    static let appStoreCountryCode = "us"
    static let adMobApplicationIdentifier = "ca-app-pub-8777918434837457~3152942210"

    enum API {
        static let cricketAustraliaBaseURL = makeURL("https://apiv2.cricket.com.au/mobile/views/")
        static let cricnetRankingsURL = makeURL("http://dabbatoken.cricnet.co.in/api/values/Ranking")
        static let iTunesLookupURL = makeURL("https://itunes.apple.com/lookup")
    }

    enum Firestore {
        static let adConfigurationCollection = "ad_configuration"
    }

    private static func makeURL(_ value: String) -> URL {
        guard let url = URL(string: value) else {
            preconditionFailure("Invalid static URL: \(value)")
        }
        return url
    }
}
