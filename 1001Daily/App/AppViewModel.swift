import Foundation
import AppKit
import Observation

@Observable
@MainActor
final class AppViewModel {
    // Current recommendations
    var currentMovie: Movie?
    var currentAlbum: Album?
    var moviePosterImage: NSImage?
    var albumCoverImage: NSImage?

    // Progress
    var movieCompletedCount: Int = 0
    var albumCompletedCount: Int = 0

    // History
    var historyEntries: [HistoryEntry] = []

    // UI state
    var isLoadingMovie = false
    var isLoadingAlbum = false
    var movieError: String?
    var albumError: String?
    var allMoviesCompleted = false
    var allAlbumsCompleted = false

    // Dependencies
    private let engine: RecommendationEngine
    private let movieRepo: MovieRepository
    private let albumRepo: AlbumRepository
    private let historyRepo: HistoryRepository
    private let recommendationRepo: RecommendationRepository
    private let tmdb: TMDBService
    private let musicBrainz: MusicBrainzService
    private let imageCache: ImageCacheService

    init(
        engine: RecommendationEngine,
        movieRepo: MovieRepository,
        albumRepo: AlbumRepository,
        historyRepo: HistoryRepository,
        recommendationRepo: RecommendationRepository,
        tmdb: TMDBService,
        musicBrainz: MusicBrainzService,
        imageCache: ImageCacheService
    ) {
        self.engine = engine
        self.movieRepo = movieRepo
        self.albumRepo = albumRepo
        self.historyRepo = historyRepo
        self.recommendationRepo = recommendationRepo
        self.tmdb = tmdb
        self.musicBrainz = musicBrainz
        self.imageCache = imageCache
    }

    // MARK: - Refresh on popover open

    func refreshRecommendations() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadMovie() }
            group.addTask { await self.loadAlbum() }
            group.addTask { await self.loadProgress() }
        }
    }

    // MARK: - Movie

    private func loadMovie() async {
        isLoadingMovie = true
        movieError = nil
        do {
            let movie = try await engine.currentMovie()
            currentMovie = movie
            await fetchMoviePoster(movie: movie)
        } catch RecommendationError.allMoviesCompleted {
            allMoviesCompleted = true
            currentMovie = nil
        } catch {
            movieError = error.localizedDescription
        }
        isLoadingMovie = false
    }

    private func fetchMoviePoster(movie: Movie) async {
        // Load cached poster immediately if available
        if let posterPath = movie.posterPath, !posterPath.isEmpty {
            let url = URL(string: "\(TMDBService.imageBaseURL)\(posterPath)")!
            let image = try? await imageCache.image(for: url)
            // Guard: si la película cambió mientras esperábamos, no actualizar la UI
            guard currentMovie?.id == movie.id else { return }
            moviePosterImage = image
            // Still fetch missing metadata if needed
            let needsTrailer = movie.trailerYouTubeKey == nil
            let needsRating = movie.tmdbRating == nil
            if (needsTrailer || needsRating), let tmdbId = movie.tmdbId {
                if needsTrailer, let key = try? await tmdb.fetchTrailerKey(tmdbId: tmdbId) {
                    guard currentMovie?.id == movie.id else { return }
                    try? await movieRepo.updateTrailerKey(id: movie.id, trailerYouTubeKey: key)
                    currentMovie?.trailerYouTubeKey = key
                }
                if needsRating, let detail = try? await tmdb.fetchMovieDetails(tmdbId: tmdbId),
                   let rating = detail.voteAverage, rating > 0 {
                    guard currentMovie?.id == movie.id else { return }
                    try? await movieRepo.updateRating(id: movie.id, tmdbRating: rating)
                    currentMovie?.tmdbRating = rating
                }
            }
            return
        }
        guard let tmdbId = movie.tmdbId else { return }
        do {
            async let detailFetch = tmdb.fetchMovieDetails(tmdbId: tmdbId)
            async let trailerFetch = tmdb.fetchTrailerKey(tmdbId: tmdbId)
            let detail = try await detailFetch
            let trailerKey = try? await trailerFetch
            // Guard tras el await de red: verificar que seguimos mostrando la misma película
            guard currentMovie?.id == movie.id else { return }
            if let path = detail.posterPath {
                let url = await tmdb.posterURL(for: path)
                let image = try? await imageCache.image(for: url)
                // Guard nuevamente tras el await de imagen
                guard currentMovie?.id == movie.id else { return }
                moviePosterImage = image
                try? await movieRepo.updatePosterPath(id: movie.id, posterPath: path)
                currentMovie?.posterPath = path
            }
            if currentMovie?.imdbId == nil, let imdbId = detail.imdbId {
                currentMovie?.imdbId = imdbId
            }
            if currentMovie?.overview == nil, let ov = detail.overview, !ov.isEmpty {
                currentMovie?.overview = ov
            }
            if let key = trailerKey {
                try? await movieRepo.updateTrailerKey(id: movie.id, trailerYouTubeKey: key)
                currentMovie?.trailerYouTubeKey = key
            }
            if let rating = detail.voteAverage, rating > 0 {
                try? await movieRepo.updateRating(id: movie.id, tmdbRating: rating)
                currentMovie?.tmdbRating = rating
            }
        } catch {
            print("TMDB fetch failed: \(error)")
        }
    }

    func markMovieWatched(rating: Double?, notes: String?) async {
        guard let movie = currentMovie else { return }
        isLoadingMovie = true
        moviePosterImage = nil
        do {
            let newMovie = try await engine.completeMovie(
                id: movie.id, title: movie.title, year: movie.year,
                director: movie.director, rating: rating, notes: notes
            )
            currentMovie = newMovie
            await fetchMoviePoster(movie: newMovie)
            await loadProgress()
            await loadHistory()
        } catch RecommendationError.allMoviesCompleted {
            allMoviesCompleted = true
            currentMovie = nil
        } catch {
            movieError = error.localizedDescription
        }
        isLoadingMovie = false
    }

    func skipMovie() async {
        guard let movie = currentMovie else { return }
        isLoadingMovie = true
        moviePosterImage = nil
        do {
            let newMovie = try await engine.skipMovie()
            // If we got the same movie back (only one unseen), keep it
            if newMovie.id != movie.id {
                currentMovie = newMovie
                await fetchMoviePoster(movie: newMovie)
            } else {
                currentMovie = newMovie
                await fetchMoviePoster(movie: newMovie)
            }
        } catch RecommendationError.allMoviesCompleted {
            allMoviesCompleted = true
            currentMovie = nil
        } catch {
            movieError = error.localizedDescription
        }
        isLoadingMovie = false
    }

    // MARK: - Album

    private func loadAlbum() async {
        isLoadingAlbum = true
        albumError = nil
        do {
            let album = try await engine.currentAlbum()
            currentAlbum = album
            await fetchAlbumCover(album: album)
        } catch RecommendationError.allAlbumsCompleted {
            allAlbumsCompleted = true
            currentAlbum = nil
        } catch {
            albumError = error.localizedDescription
        }
        isLoadingAlbum = false
    }

    private func fetchAlbumCover(album: Album) async {
        if let coverPath = album.coverArtPath, !coverPath.isEmpty {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let diskURL = appSupport.appendingPathComponent("1001Daily/ImageCache/\(coverPath)")
            if let image = NSImage(contentsOf: diskURL) {
                albumCoverImage = image
                return
            }
            // El archivo no existe en disco (cache borrada o path obsoleto) — limpiar en memoria y re-fetchear
            currentAlbum?.coverArtPath = nil
        }
        // iTunes Search API: reliable, no auth, no rate limit
        if let coverURL = await fetchITunesCoverURL(artist: album.artist, title: album.title) {
            albumCoverImage = try? await imageCache.image(for: coverURL)
            if let filename = await imageCache.cachedFilename(for: coverURL) {
                try? await albumRepo.updateCoverArtPath(id: album.id, coverArtPath: filename)
                currentAlbum?.coverArtPath = filename
            }
            return
        }
        // Fallback: MusicBrainz Cover Art Archive
        var mbId = album.musicbrainzId
        if mbId == nil {
            mbId = try? await musicBrainz.searchAlbum(artist: album.artist, title: album.title)
            if let foundId = mbId {
                try? await albumRepo.updateMusicBrainzId(id: album.id, musicbrainzId: foundId)
                currentAlbum?.musicbrainzId = foundId
            }
        }
        guard let mbId = mbId else { return }
        do {
            if let coverURL = try await musicBrainz.fetchCoverArtURL(releaseGroupId: mbId) {
                albumCoverImage = try? await imageCache.image(for: coverURL)
                if let filename = await imageCache.cachedFilename(for: coverURL) {
                    try? await albumRepo.updateCoverArtPath(id: album.id, coverArtPath: filename)
                    currentAlbum?.coverArtPath = filename
                }
            }
        } catch {
            print("Cover art fetch failed: \(error)")
        }
    }

    private func fetchITunesCoverURL(artist: String, title: String) async -> URL? {
        let query = "\(artist) \(title)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "https://itunes.apple.com/search?term=\(query)&entity=album&limit=1") else { return nil }
        struct ITunesResponse: Decodable {
            struct Result: Decodable { let artworkUrl100: String }
            let results: [Result]
        }
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let parsed = try? JSONDecoder().decode(ITunesResponse.self, from: data),
              let artworkStr = parsed.results.first?.artworkUrl100 else { return nil }
        let highRes = artworkStr.replacingOccurrences(of: "100x100bb", with: "500x500bb")
        return URL(string: highRes)
    }

    func skipAlbum() async {
        guard let album = currentAlbum else { return }
        isLoadingAlbum = true
        albumCoverImage = nil
        do {
            let newAlbum = try await engine.skipAlbum()
            currentAlbum = newAlbum
            await fetchAlbumCover(album: newAlbum)
        } catch RecommendationError.allAlbumsCompleted {
            allAlbumsCompleted = true
            currentAlbum = nil
        } catch {
            albumError = error.localizedDescription
        }
        isLoadingAlbum = false
    }

    func markAlbumListened(rating: Double?, notes: String?) async {
        guard let album = currentAlbum else { return }
        isLoadingAlbum = true
        albumCoverImage = nil
        do {
            let newAlbum = try await engine.completeAlbum(
                id: album.id, title: album.title, year: album.year,
                artist: album.artist, rating: rating, notes: notes
            )
            currentAlbum = newAlbum
            await fetchAlbumCover(album: newAlbum)
            await loadProgress()
            await loadHistory()
        } catch RecommendationError.allAlbumsCompleted {
            allAlbumsCompleted = true
            currentAlbum = nil
        } catch {
            albumError = error.localizedDescription
        }
        isLoadingAlbum = false
    }

    // MARK: - Progress & History

    func loadProgress() async {
        do {
            movieCompletedCount = try await historyRepo.count(type: .movie)
            albumCompletedCount = try await historyRepo.count(type: .album)
        } catch {
            print("loadProgress failed: \(error)")
        }
    }

    func loadHistory() async {
        do {
            historyEntries = try await historyRepo.fetchAll()
        } catch {
            print("loadHistory failed: \(error)")
        }
    }

    func deleteHistoryEntry(id: Int) async {
        do {
            try await historyRepo.deleteEntry(id: id)
            historyEntries.removeAll { $0.id == id }
            await loadProgress()
        } catch {
            print("deleteHistoryEntry failed: \(error)")
        }
    }

    // MARK: - Reset

    func resetAllData() async {
        do {
            try await historyRepo.deleteAll()
            try await recommendationRepo.deleteAll()
            movieCompletedCount = 0
            albumCompletedCount = 0
            historyEntries = []
            allMoviesCompleted = false
            allAlbumsCompleted = false
            currentMovie = nil
            currentAlbum = nil
            moviePosterImage = nil
            albumCoverImage = nil
            await refreshRecommendations()
        } catch {
            print("resetAllData failed: \(error)")
        }
    }
}
