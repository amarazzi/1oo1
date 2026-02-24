import Foundation

enum RecommendationError: Error, LocalizedError {
    case allMoviesCompleted
    case allAlbumsCompleted
    case movieNotFound(Int)
    case albumNotFound(Int)

    var errorDescription: String? {
        switch self {
        case .allMoviesCompleted: return "You've watched all 1001 movies! Congratulations!"
        case .allAlbumsCompleted: return "You've listened to all 1001 albums! Congratulations!"
        case .movieNotFound(let id): return "Movie with id \(id) not found."
        case .albumNotFound(let id): return "Album with id \(id) not found."
        }
    }
}

final class RecommendationEngine {
    private let movieRepo: MovieRepository
    private let albumRepo: AlbumRepository
    private let recommendationRepo: RecommendationRepository
    private let historyRepo: HistoryRepository

    /// Fixed key used instead of date strings — recommendations only change on user action
    private static let movieKey = "current_movie"
    private static let albumKey = "current_album"

    init(
        movieRepo: MovieRepository,
        albumRepo: AlbumRepository,
        recommendationRepo: RecommendationRepository,
        historyRepo: HistoryRepository
    ) {
        self.movieRepo = movieRepo
        self.albumRepo = albumRepo
        self.recommendationRepo = recommendationRepo
        self.historyRepo = historyRepo
    }

    // MARK: - Current recommendations

    func currentMovie() async throws -> Movie {
        if let existing = try await recommendationRepo.find(type: .movie, dateString: Self.movieKey) {
            guard let movie = try await movieRepo.fetch(id: existing.itemId) else {
                throw RecommendationError.movieNotFound(existing.itemId)
            }
            return movie
        }

        let seenIds = try await historyRepo.completedItemIds(type: .movie)
        guard let newMovie = try await movieRepo.randomUnseen(excluding: seenIds) else {
            throw RecommendationError.allMoviesCompleted
        }

        let rec = Recommendation(
            itemId: newMovie.id,
            itemType: .movie,
            assignedDate: Self.movieKey
        )
        try await recommendationRepo.save(rec)
        return newMovie
    }

    func currentAlbum() async throws -> Album {
        if let existing = try await recommendationRepo.find(type: .album, dateString: Self.albumKey) {
            guard let album = try await albumRepo.fetch(id: existing.itemId) else {
                throw RecommendationError.albumNotFound(existing.itemId)
            }
            return album
        }

        let seenIds = try await historyRepo.completedItemIds(type: .album)
        guard let newAlbum = try await albumRepo.randomUnseen(excluding: seenIds) else {
            throw RecommendationError.allAlbumsCompleted
        }

        let rec = Recommendation(
            itemId: newAlbum.id,
            itemType: .album,
            assignedDate: Self.albumKey
        )
        try await recommendationRepo.save(rec)
        return newAlbum
    }

    // MARK: - Complete item (mark as watched/listened, removes from pool)

    func completeMovie(id: Int, title: String, year: Int, director: String,
                       rating: Double?, notes: String?) async throws -> Movie {
        let entry = HistoryEntry(
            itemId: id,
            itemType: .movie,
            dateCompleted: todayDateString(),
            rating: rating,
            notes: notes,
            title: title,
            year: year,
            artist: nil,
            director: director
        )
        try await historyRepo.save(entry)
        // Delete current rec so a new one is picked (completed item excluded via history)
        try await recommendationRepo.delete(type: .movie, dateString: Self.movieKey)
        return try await currentMovie()
    }

    func completeAlbum(id: Int, title: String, year: Int, artist: String,
                       rating: Double?, notes: String?) async throws -> Album {
        let entry = HistoryEntry(
            itemId: id,
            itemType: .album,
            dateCompleted: todayDateString(),
            rating: rating,
            notes: notes,
            title: title,
            year: year,
            artist: artist,
            director: nil
        )
        try await historyRepo.save(entry)
        // Delete current rec so a new one is picked (completed item excluded via history)
        try await recommendationRepo.delete(type: .album, dateString: Self.albumKey)
        return try await currentAlbum()
    }

    // MARK: - Skip item (random without removing from pool)

    func skipMovie() async throws -> Movie {
        let seenIds = try await historyRepo.completedItemIds(type: .movie)

        // Exclude current movie too so we always get something different
        var excludeIds = seenIds
        if let existing = try await recommendationRepo.find(type: .movie, dateString: Self.movieKey) {
            excludeIds.insert(existing.itemId)
        }

        guard let newMovie = try await movieRepo.randomUnseen(excluding: excludeIds) else {
            // Only one unseen movie left — just return it as-is
            guard let only = try await movieRepo.randomUnseen(excluding: seenIds) else {
                throw RecommendationError.allMoviesCompleted
            }
            try await recommendationRepo.update(type: .movie, dateString: Self.movieKey, itemId: only.id)
            return only
        }

        try await recommendationRepo.update(type: .movie, dateString: Self.movieKey, itemId: newMovie.id)
        return newMovie
    }

    func skipAlbum() async throws -> Album {
        let seenIds = try await historyRepo.completedItemIds(type: .album)

        var excludeIds = seenIds
        if let existing = try await recommendationRepo.find(type: .album, dateString: Self.albumKey) {
            excludeIds.insert(existing.itemId)
        }

        guard let newAlbum = try await albumRepo.randomUnseen(excluding: excludeIds) else {
            guard let only = try await albumRepo.randomUnseen(excluding: seenIds) else {
                throw RecommendationError.allAlbumsCompleted
            }
            try await recommendationRepo.update(type: .album, dateString: Self.albumKey, itemId: only.id)
            return only
        }

        try await recommendationRepo.update(type: .album, dateString: Self.albumKey, itemId: newAlbum.id)
        return newAlbum
    }

    // MARK: - Date helpers

    private func todayDateString() -> String {
        Recommendation.dateString(from: Calendar.current.startOfDay(for: Date()))
    }
}
