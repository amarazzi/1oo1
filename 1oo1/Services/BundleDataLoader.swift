import Foundation

enum BundleDataError: Error {
    case fileNotFound(String)
}

// JSON structures for decoding bundled data
private struct MovieJSON: Decodable {
    let id: Int
    let title: String
    let year: Int
    let director: String
    let genre: String
    let tmdb_id: Int?
    let imdb_id: String?
    let overview: String?
    let runtime_minutes: Int?
}

private struct AlbumJSON: Decodable {
    let id: Int
    let title: String
    let year: Int
    let artist: String
    let genre: String
    let musicbrainz_id: String?
    let description: String?
}

enum BundleDataLoader {
    static func loadMovies() throws -> [Movie] {
        guard let url = Bundle.main.url(forResource: "movies_1001", withExtension: "json") else {
            throw BundleDataError.fileNotFound("movies_1001.json")
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([MovieJSON].self, from: data)
        return raw.map { j in
            Movie(
                id: j.id,
                title: j.title,
                year: j.year,
                director: j.director,
                genre: j.genre,
                tmdbId: j.tmdb_id,
                imdbId: j.imdb_id,
                overview: j.overview,
                runtimeMinutes: j.runtime_minutes,
                posterPath: nil
            )
        }
    }

    static func loadAlbums() throws -> [Album] {
        guard let url = Bundle.main.url(forResource: "albums_1001", withExtension: "json") else {
            throw BundleDataError.fileNotFound("albums_1001.json")
        }
        let data = try Data(contentsOf: url)
        let raw = try JSONDecoder().decode([AlbumJSON].self, from: data)
        return raw.map { j in
            Album(
                id: j.id,
                title: j.title,
                year: j.year,
                artist: j.artist,
                genre: j.genre,
                musicbrainzId: j.musicbrainz_id,
                description: j.description,
                coverArtPath: nil
            )
        }
    }

    static func seedIfNeeded(movieRepo: MovieRepository, albumRepo: AlbumRepository) async {
        do {
            let movieCount = try await movieRepo.count()
            let movies = try loadMovies()
            if movieCount == 0 {
                try await movieRepo.insertBatch(movies)
                print("BundleDataLoader: seeded \(movies.count) movies")
            } else if movieCount < movies.count {
                // Backfill: insertar películas nuevas del JSON que no estén en la DB
                try await movieRepo.insertOrIgnoreBatch(movies)
                let newCount = try await movieRepo.count()
                print("BundleDataLoader: backfilled movies \(movieCount) → \(newCount)")
            }

            let albumCount = try await albumRepo.count()
            let albums = try loadAlbums()
            if albumCount == 0 {
                try await albumRepo.insertBatch(albums)
                print("BundleDataLoader: seeded \(albums.count) albums")
            } else {
                if albumCount < albums.count {
                    // Backfill: insertar álbumes nuevos del JSON que no estén en la DB
                    try await albumRepo.insertOrIgnoreBatch(albums)
                    let newCount = try await albumRepo.count()
                    print("BundleDataLoader: backfilled albums \(albumCount) → \(newCount)")
                }
                // Backfill musicbrainzId para álbumes que no lo tengan aún
                for album in albums {
                    guard let mbId = album.musicbrainzId else { continue }
                    try await albumRepo.updateMusicBrainzId(id: album.id, musicbrainzId: mbId)
                }
                print("BundleDataLoader: backfilled musicbrainzIds for \(albums.filter { $0.musicbrainzId != nil }.count) albums")
                // Backfill descriptions for albums that have empty/null description in DB
                try await albumRepo.updateDescriptionsBatch(albums)
                print("BundleDataLoader: backfilled descriptions for \(albums.filter { $0.description != nil && !($0.description!.isEmpty) }.count) albums")
            }
        } catch {
            print("BundleDataLoader seed failed: \(error)")
        }
    }
}
