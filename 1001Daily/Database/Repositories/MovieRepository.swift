import Foundation
import GRDB

final class MovieRepository {
    private let db: DatabaseManager

    init(db: DatabaseManager) {
        self.db = db
    }

    func count() async throws -> Int {
        try await db.dbQueue.read { db in
            try Movie.fetchCount(db)
        }
    }

    func fetch(id: Int) async throws -> Movie? {
        try await db.dbQueue.read { db in
            try Movie.fetchOne(db, key: id)
        }
    }

    func randomUnseen(excluding seenIds: Set<Int>) async throws -> Movie? {
        try await db.dbQueue.read { db in
            if seenIds.isEmpty {
                return try Movie.order(sql: "RANDOM()").fetchOne(db)
            }
            let placeholders = seenIds.map { _ in "?" }.joined(separator: ",")
            let args = StatementArguments(seenIds.map { DatabaseValue(value: $0) })
            return try Movie
                .filter(sql: "id NOT IN (\(placeholders))", arguments: args)
                .order(sql: "RANDOM()")
                .fetchOne(db)
        }
    }

    func insertBatch(_ movies: [Movie]) async throws {
        try await db.dbQueue.write { db in
            for movie in movies {
                try movie.insert(db)
            }
        }
    }

    func insertOrIgnoreBatch(_ movies: [Movie]) async throws {
        try await db.dbQueue.write { db in
            for movie in movies {
                try movie.insertAndFetch(db, onConflict: .ignore)
            }
        }
    }

    func updatePosterPath(id: Int, posterPath: String) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE movies SET posterPath = ? WHERE id = ?",
                arguments: [posterPath, id]
            )
        }
    }

    func updateRating(id: Int, tmdbRating: Double) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE movies SET tmdbRating = ? WHERE id = ?",
                arguments: [tmdbRating, id]
            )
        }
    }

    func updateTrailerKey(id: Int, trailerYouTubeKey: String) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE movies SET trailerYouTubeKey = ? WHERE id = ?",
                arguments: [trailerYouTubeKey, id]
            )
        }
    }

    func completedIds() async throws -> Set<Int> {
        try await db.dbQueue.read { db in
            let ids = try Int.fetchAll(db, sql: "SELECT itemId FROM history WHERE itemType = 'movie'")
            return Set(ids)
        }
    }

    func deleteAll() async throws {
        try await db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM movies")
        }
    }
}
