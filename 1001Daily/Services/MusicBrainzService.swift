import Foundation

struct CoverArtArchiveResponse: Decodable {
    let images: [CoverArtImage]

    struct CoverArtImage: Decodable {
        let image: String
        let front: Bool
        let thumbnails: Thumbnails

        struct Thumbnails: Decodable {
            let small: String?
            let large: String?

            enum CodingKeys: String, CodingKey {
                case small = "250"
                case large = "500"
            }
        }
    }
}

actor MusicBrainzService {
    private let userAgent = "1001Daily/1.0 (contact@example.com)"
    private let baseURL = "https://musicbrainz.org/ws/2"
    private let coverArtBaseURL = "https://coverartarchive.org/release-group"

    func fetchCoverArtURL(releaseGroupId: String) async throws -> URL? {
        let urlStr = "\(coverArtBaseURL)/\(releaseGroupId)"
        var request = URLRequest(url: URL(string: urlStr)!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        let result = try JSONDecoder().decode(CoverArtArchiveResponse.self, from: data)

        // Prefer front cover art
        let frontImage = result.images.first(where: { $0.front }) ?? result.images.first
        guard let imageStr = frontImage?.thumbnails.large ?? frontImage?.thumbnails.small ?? frontImage?.image else {
            return nil
        }
        return URL(string: imageStr)
    }

    func searchAlbum(artist: String, title: String) async throws -> String? {
        var components = URLComponents(string: "\(baseURL)/release-group")!
        components.queryItems = [
            URLQueryItem(name: "query", value: "artist:\"\(artist)\" releasegroup:\"\(title)\""),
            URLQueryItem(name: "fmt", value: "json"),
            URLQueryItem(name: "limit", value: "1")
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // MusicBrainz rate limit: 1 req/sec
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        struct SearchResponse: Decodable {
            struct ReleaseGroup: Decodable {
                let id: String
            }
            let releaseGroups: [ReleaseGroup]
            enum CodingKeys: String, CodingKey {
                case releaseGroups = "release-groups"
            }
        }

        let result = try JSONDecoder().decode(SearchResponse.self, from: data)
        return result.releaseGroups.first?.id
    }
}
