import Foundation

// MARK: - View State

/// Strongly typed screen state shared across ViewModels.
enum ViewState<Data: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Data)
    case refreshing(Data)
    case empty
    case error(String)
    case offline(Data, lastUpdated: Date)

    var data: Data? {
        switch self {
        case let .loaded(data), let .refreshing(data), let .offline(data, _):
            data
        case .idle, .loading, .empty, .error:
            nil
        }
    }

    var isLoading: Bool {
        if case .loading = self { true } else { false }
    }

    var isRefreshing: Bool {
        if case .refreshing = self { true } else { false }
    }

    var errorMessage: String? {
        if case let .error(message) = self { message } else { nil }
    }

    var lastUpdated: Date? {
        if case let .offline(_, date) = self { date } else { nil }
    }

    var isOffline: Bool {
        if case .offline = self { true } else { false }
    }
}
