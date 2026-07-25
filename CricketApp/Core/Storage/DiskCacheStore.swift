import Foundation

// MARK: - Disk Cache Store

/// Persists codable payloads for offline access.
actor DiskCacheStore {
    static let shared = DiskCacheStore()

    private let directory: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.directory = base.appendingPathComponent("CricketCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func save<T: Encodable>(_ value: T, key: String, updatedAt: Date = .now) throws {
        let payload = CachedPayloadEncoder(updatedAt: updatedAt, data: value)
        let encoded = try encoder.encode(payload)
        try encoded.write(to: fileURL(for: key), options: .atomic)
    }

    func load<T: Decodable>(_ type: T.Type, key: String) -> (value: T, updatedAt: Date)? {
        guard let data = try? Data(contentsOf: fileURL(for: key)),
              let payload = try? decoder.decode(CachedPayloadDecoder<T>.self, from: data) else {
            return nil
        }

        return (payload.data, payload.updatedAt)
    }
    private func fileURL(for key: String) -> URL {
        let safeName = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return directory.appendingPathComponent("\(safeName).json")
    }
}

// MARK: - Cached Payload

private struct CachedPayloadEncoder<T: Encodable>: Encodable {
    let updatedAt: Date
    let data: T
}

private struct CachedPayloadDecoder<T: Decodable>: Decodable {
    let updatedAt: Date
    let data: T
}
