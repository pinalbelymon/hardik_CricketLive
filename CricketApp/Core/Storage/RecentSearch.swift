import Foundation
import SwiftData

// MARK: - Recent Search

/// SwiftData-backed search history entry used by search surfaces.
@Model
final class RecentSearch {
    var query: String
    var createdAt: Date

    init(query: String, createdAt: Date = .now) {
        self.query = query
        self.createdAt = createdAt
    }
}
