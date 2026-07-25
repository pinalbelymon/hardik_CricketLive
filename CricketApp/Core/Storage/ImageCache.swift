import Foundation
import SwiftUI

// MARK: - Image Cache

/// Configures URLCache and provides cached image loading for remote assets.
enum ImageCache {
    static func configureSharedCache() {
        let memoryCapacity = 50 * 1024 * 1024
        let diskCapacity = 200 * 1024 * 1024
        URLCache.shared = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
    }

    static func image(for url: URL) async -> UIImage? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)

        if let cached = URLCache.shared.cachedResponse(for: request),
           let image = UIImage(data: cached.data) {
            return image
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let cachedResponse = CachedURLResponse(response: response, data: data)
            URLCache.shared.storeCachedResponse(cachedResponse, for: request)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}

// MARK: - Cached Async Image

/// Loads and caches competition, team, venue, and player images.
struct CachedAsyncImage<Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder

    @State private var image: UIImage?

    init(url: URL?, @ViewBuilder placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            guard let url else {
                image = nil
                return
            }
            image = await ImageCache.image(for: url)
        }
    }
}
