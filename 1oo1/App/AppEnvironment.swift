import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let db: DatabaseManager
    let movieRepo: MovieRepository
    let albumRepo: AlbumRepository
    let recommendationRepo: RecommendationRepository
    let historyRepo: HistoryRepository
    let tmdb: TMDBService
    let musicBrainz: MusicBrainzService
    let imageCache: ImageCacheService
    let engine: RecommendationEngine
    let viewModel: AppViewModel

    init() {
        db = DatabaseManager()
        movieRepo = MovieRepository(db: db)
        albumRepo = AlbumRepository(db: db)
        recommendationRepo = RecommendationRepository(db: db)
        historyRepo = HistoryRepository(db: db)
        tmdb = TMDBService()
        musicBrainz = MusicBrainzService()
        imageCache = ImageCacheService()
        engine = RecommendationEngine(
            movieRepo: movieRepo,
            albumRepo: albumRepo,
            recommendationRepo: recommendationRepo,
            historyRepo: historyRepo
        )
        viewModel = AppViewModel(
            engine: engine,
            movieRepo: movieRepo,
            albumRepo: albumRepo,
            historyRepo: historyRepo,
            recommendationRepo: recommendationRepo,
            tmdb: tmdb,
            musicBrainz: musicBrainz,
            imageCache: imageCache
        )

        // Seed DB from bundled JSON on first launch
        Task {
            await BundleDataLoader.seedIfNeeded(movieRepo: movieRepo, albumRepo: albumRepo)
        }
    }
}

// MARK: - SwiftUI environment key

private struct AppEnvironmentKey: EnvironmentKey {
    @MainActor
    static let defaultValue: AppEnvironment = AppEnvironment()
}

extension EnvironmentValues {
    var appEnvironment: AppEnvironment {
        get { self[AppEnvironmentKey.self] }
        set { self[AppEnvironmentKey.self] = newValue }
    }
}
