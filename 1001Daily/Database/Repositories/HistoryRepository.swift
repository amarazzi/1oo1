import Foundation
import GRDB

final class HistoryRepository {
    private let db: DatabaseManager

    init(db: DatabaseManager) {
        self.db = db
    }

    func save(_ entry: HistoryEntry) async throws {
        try await db.dbQueue.write { db in
            var e = entry
            try e.insert(db)
        }
    }

    func fetchAll() async throws -> [HistoryEntry] {
        try await db.dbQueue.read { db in
            try HistoryEntry
                .order(HistoryEntry.Columns.dateCompleted.desc)
                .fetchAll(db)
        }
    }

    func completedItemIds(type: Recommendation.ItemType) async throws -> Set<Int> {
        try await db.dbQueue.read { db in
            let ids = try Int.fetchAll(
                db,
                sql: "SELECT itemId FROM history WHERE itemType = ?",
                arguments: [type.rawValue]
            )
            return Set(ids)
        }
    }

    func count(type: Recommendation.ItemType) async throws -> Int {
        try await db.dbQueue.read { db in
            try Int.fetchOne(
                db,
                sql: "SELECT COUNT(*) FROM history WHERE itemType = ?",
                arguments: [type.rawValue]
            ) ?? 0
        }
    }

    func deleteEntry(id: Int) async throws {
        try await db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM history WHERE id = ?", arguments: [id])
        }
    }

    func deleteAll() async throws {
        try await db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM history")
        }
    }
}
