import AppKit
import CryptoKit
import Foundation

enum ImageCacheError: Error {
    case invalidData
    case invalidURL
}

actor ImageCacheService {
    private let memoryCache = NSCache<NSString, NSImage>()
    private let diskCacheDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        diskCacheDirectory = appSupport.appendingPathComponent("1oo1/ImageCache")
        try? FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 50
        memoryCache.totalCostLimit = 50 * 1024 * 1024  // 50MB
    }

    /// Genera un nombre de archivo único y colisión-seguro usando SHA256 de la URL completa.
    private func cacheFilename(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined() + ".img"
    }

    func image(for url: URL) async throws -> NSImage {
        let key = url.absoluteString as NSString
        let filename = cacheFilename(for: url)

        // 1. Memory cache
        if let cached = memoryCache.object(forKey: key) {
            return cached
        }

        // 2. Disk cache
        let diskURL = diskCacheDirectory.appendingPathComponent(filename)
        if FileManager.default.fileExists(atPath: diskURL.path),
           let image = NSImage(contentsOf: diskURL) {
            memoryCache.setObject(image, forKey: key)
            return image
        }

        // 3. Network fetch
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = NSImage(data: data) else {
            throw ImageCacheError.invalidData
        }

        try data.write(to: diskURL)
        memoryCache.setObject(image, forKey: key)
        return image
    }

    /// Returns the local disk cache filename for a URL if cached
    func cachedFilename(for url: URL) -> String? {
        let filename = cacheFilename(for: url)
        let diskURL = diskCacheDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: diskURL.path) ? filename : nil
    }

    func clearAll() throws {
        try FileManager.default.removeItem(at: diskCacheDirectory)
        try FileManager.default.createDirectory(at: diskCacheDirectory, withIntermediateDirectories: true)
        memoryCache.removeAllObjects()
    }
}
