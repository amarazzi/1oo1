import Foundation
import GRDB

struct Movie: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int
    var title: String
    var year: Int
    var director: String
    var genre: String
    var tmdbId: Int?
    var imdbId: String?
    var overview: String?
    var runtimeMinutes: Int?
    var posterPath: String?  // local cache filename (filled after first fetch)
    var trailerYouTubeKey: String?  // YouTube video key (filled after first TMDB fetch)
    var tmdbRating: Double?         // TMDB community rating 0–10 (filled after first TMDB fetch)

    static let databaseTableName = "movies"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let year = Column(CodingKeys.year)
        static let director = Column(CodingKeys.director)
        static let genre = Column(CodingKeys.genre)
        static let tmdbId = Column(CodingKeys.tmdbId)
        static let imdbId = Column(CodingKeys.imdbId)
        static let overview = Column(CodingKeys.overview)
        static let runtimeMinutes = Column(CodingKeys.runtimeMinutes)
        static let posterPath = Column(CodingKeys.posterPath)
        static let trailerYouTubeKey = Column(CodingKeys.trailerYouTubeKey)
        static let tmdbRating = Column(CodingKeys.tmdbRating)
    }

    /// Direct YouTube link when a key is known, otherwise falls back to search
    var trailerURL: URL? {
        if let key = trailerYouTubeKey, !key.isEmpty {
            return URL(string: "https://www.youtube.com/watch?v=\(key)")
        }
        let query = "\(title) \(year) official trailer"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "https://www.youtube.com/results?search_query=\(query)")
    }

    // MARK: - Mock
    static var mock: Movie {
        Movie(
            id: 1,
            title: "Stalker",
            year: 1979,
            director: "Andrei Tarkovsky",
            genre: "Drama, Science Fiction",
            tmdbId: 10325,
            imdbId: "tt0079944",
            overview: "A guide leads two men through a mysterious forbidden zone known as the Zone, where a room exists that grants wishes.",
            runtimeMinutes: 162,
            posterPath: nil
        )
    }
}
