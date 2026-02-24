import Foundation
import GRDB

final class AlbumRepository {
    private let db: DatabaseManager

    init(db: DatabaseManager) {
        self.db = db
    }

    func count() async throws -> Int {
        try await db.dbQueue.read { db in
            try Album.fetchCount(db)
        }
    }

    func fetch(id: Int) async throws -> Album? {
        try await db.dbQueue.read { db in
            try Album.fetchOne(db, key: id)
        }
    }

    func randomUnseen(excluding seenIds: Set<Int>) async throws -> Album? {
        try await db.dbQueue.read { db in
            if seenIds.isEmpty {
                return try Album.order(sql: "RANDOM()").fetchOne(db)
            }
            let placeholders = seenIds.map { _ in "?" }.joined(separator: ",")
            let args = StatementArguments(seenIds.map { DatabaseValue(value: $0) })
            return try Album
                .filter(sql: "id NOT IN (\(placeholders))", arguments: args)
                .order(sql: "RANDOM()")
                .fetchOne(db)
        }
    }

    func insertBatch(_ albums: [Album]) async throws {
        try await db.dbQueue.write { db in
            for album in albums {
                try album.insert(db)
            }
        }
    }

    func insertOrIgnoreBatch(_ albums: [Album]) async throws {
        try await db.dbQueue.write { db in
            for album in albums {
                try album.insertAndFetch(db, onConflict: .ignore)
            }
        }
    }

    func updateMusicBrainzId(id: Int, musicbrainzId: String) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE albums SET musicbrainzId = ? WHERE id = ?",
                arguments: [musicbrainzId, id]
            )
        }
    }

    func updateCoverArtPath(id: Int, coverArtPath: String) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE albums SET coverArtPath = ? WHERE id = ?",
                arguments: [coverArtPath, id]
            )
        }
    }

    func completedIds() async throws -> Set<Int> {
        try await db.dbQueue.read { db in
            let ids = try Int.fetchAll(db, sql: "SELECT itemId FROM history WHERE itemType = 'album'")
            return Set(ids)
        }
    }

    func deleteAll() async throws {
        try await db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM albums")
        }
    }
}
