import Foundation

// MARK: - Match Feed Item

/// Match rows interleaved with native-ad slots for list feeds.
enum MatchFeedItem: Identifiable, Hashable, Sendable {
    case match(Match)
    case nativeAd(slot: Int)

    var id: String {
        switch self {
        case .match(let match):
            "match-\(match.id)"
        case .nativeAd(let slot):
            "native-ad-\(slot)"
        }
    }

    /// Inserts a native-ad slot after every `interval` match cards.
    /// Example: `interval = 4` → ad after cards 4, 8, 12…
    static func make(
        from matches: [Match],
        interval: Int,
        maxAds: Int,
        sectionKey: String = ""
    ) -> [MatchFeedItem] {
        let interval = max(1, interval)
        guard matches.count >= interval, maxAds > 0 else {
            return matches.map { .match($0) }
        }

        var items: [MatchFeedItem] = []
        items.reserveCapacity(matches.count + min(maxAds, matches.count / interval))

        var adsInserted = 0
        for (index, match) in matches.enumerated() {
            items.append(.match(match))

            let matchNumber = index + 1
            if matchNumber.isMultiple(of: interval), adsInserted < maxAds {
                items.append(.nativeAd(slot: adsInserted))
                adsInserted += 1
            }
        }

        // sectionKey kept for call-site clarity / future id namespacing
        _ = sectionKey
        return items
    }
}
