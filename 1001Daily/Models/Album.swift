import Foundation
import GRDB

struct Album: Codable, Identifiable, Hashable, FetchableRecord, PersistableRecord {
    var id: Int
    var title: String
    var year: Int
    var artist: String
    var genre: String
    var musicbrainzId: String?
    var description: String?
    var coverArtPath: String?  // local cache filename

    static let databaseTableName = "albums"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let title = Column(CodingKeys.title)
        static let year = Column(CodingKeys.year)
        static let artist = Column(CodingKeys.artist)
        static let genre = Column(CodingKeys.genre)
        static let musicbrainzId = Column(CodingKeys.musicbrainzId)
        static let description = Column(CodingKeys.description)
        static let coverArtPath = Column(CodingKeys.coverArtPath)
    }

    var spotifySearchURL: URL? {
        // URI deep link: opens Spotify app directly to search results
        let query = "album:\"\(title)\" artist:\"\(artist)\""
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        return URL(string: "spotify:search:\(query)")
    }

    // MARK: - Mock
    static var mock: Album {
        Album(
            id: 1,
            title: "Kind of Blue",
            year: 1959,
            artist: "Miles Davis",
            genre: "Jazz",
            musicbrainzId: "1b022e01-4da6-387b-8658-8678046e4cef",
            description: "A landmark album in modal jazz, featuring some of the most celebrated improvisations in the genre's history.",
            coverArtPath: nil
        )
    }
}
