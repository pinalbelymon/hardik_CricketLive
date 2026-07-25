import Foundation

// MARK: - Memory Cache

/// Thread-safe in-memory cache with TTL expiry.
actor MemoryCache<Key: Hashable & Sendable, Value: Sendable> {
    private struct Entry {
        let value: Value
        let expiry: Date
    }

    private var storage: [Key: Entry] = [:]

    func value(for key: Key, now: Date = .now) -> Value? {
        guard let entry = storage[key] else {
            return nil
        }

        if entry.expiry < now {
            storage[key] = nil
            return nil
        }

        return entry.value
    }

    func set(_ value: Value, for key: Key, ttl: TimeInterval, now: Date = .now) {
        storage[key] = Entry(value: value, expiry: now.addingTimeInterval(ttl))
    }

    func removeValue(for key: Key) {
        storage[key] = nil
    }

    func removeAll() {
        storage.removeAll()
    }
}
