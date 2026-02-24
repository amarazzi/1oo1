import Foundation

struct TMDBMovieDetail: Decodable {
    let id: Int
    let overview: String?
    let runtime: Int?
    let posterPath: String?
    let imdbId: String?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case overview
        case runtime
        case posterPath = "poster_path"
        case imdbId = "imdb_id"
        case voteAverage = "vote_average"
    }
}

struct TMDBSearchResult: Decodable {
    let results: [TMDBSearchMovie]
}

struct TMDBVideosResult: Decodable {
    struct Video: Decodable {
        let key: String
        let site: String
        let type: String
        let official: Bool?
    }
    let results: [Video]
}

struct TMDBSearchMovie: Decodable {
    let id: Int
    let title: String
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case releaseDate = "release_date"
    }
}

actor TMDBService {
    private let apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    static let imageBaseURL = "https://image.tmdb.org/t/p/w342"

    init() {
        // Try to read from Info.plist first (Xcode build with xcconfig)
        if let key = Bundle.main.infoDictionary?["TMDBAPIKey"] as? String, !key.isEmpty {
            self.apiKey = key
        } else {
            // Fallback: read from ~/.1001daily_config file
            let configURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".1001daily_config")
            let contents = (try? String(contentsOf: configURL, encoding: .utf8)) ?? ""
            let key = contents
                .components(separatedBy: "\n")
                .first(where: { $0.hasPrefix("TMDB_API_KEY=") })?
                .replacingOccurrences(of: "TMDB_API_KEY=", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.apiKey = key
        }
    }

    func fetchMovieDetails(tmdbId: Int) async throws -> TMDBMovieDetail {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        let url = URL(string: "\(baseURL)/movie/\(tmdbId)?api_key=\(apiKey)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TMDBError.badResponse
        }
        return try JSONDecoder().decode(TMDBMovieDetail.self, from: data)
    }

    func searchMovie(title: String, year: Int) async throws -> Int? {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        var components = URLComponents(string: "\(baseURL)/search/movie")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: title),
            URLQueryItem(name: "year", value: String(year))
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TMDBError.badResponse
        }
        let result = try JSONDecoder().decode(TMDBSearchResult.self, from: data)
        return result.results.first?.id
    }

    func posterURL(for path: String) -> URL {
        URL(string: "\(Self.imageBaseURL)\(path)")!
    }

    /// Returns the YouTube video key for the official trailer of a movie.
    func fetchTrailerKey(tmdbId: Int) async throws -> String? {
        guard !apiKey.isEmpty else { throw TMDBError.missingAPIKey }
        let url = URL(string: "\(baseURL)/movie/\(tmdbId)/videos?api_key=\(apiKey)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw TMDBError.badResponse
        }
        let result = try JSONDecoder().decode(TMDBVideosResult.self, from: data)
        // Prefer official trailers, then any trailer
        let trailers = result.results.filter { $0.site == "YouTube" && $0.type == "Trailer" }
        let official = trailers.first(where: { $0.official == true }) ?? trailers.first
        return official?.key
    }
}

enum TMDBError: Error, LocalizedError {
    case missingAPIKey
    case badResponse
    case notFound

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "TMDB API key not configured."
        case .badResponse: return "TMDB returned an unexpected response."
        case .notFound: return "Movie not found on TMDB."
        }
    }
}
