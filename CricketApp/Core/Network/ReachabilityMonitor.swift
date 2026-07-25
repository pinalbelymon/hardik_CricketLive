import Foundation
@preconcurrency import Network

// MARK: - Reachability Monitor

/// Publishes coarse network reachability changes for error state presentation.
@MainActor
final class ReachabilityMonitor: ObservableObject {
    @Published private(set) var isReachable = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "cricket.reachability.monitor")

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isReachable = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
