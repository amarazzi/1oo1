import Foundation
import GRDB

final class RecommendationRepository {
    private let db: DatabaseManager

    init(db: DatabaseManager) {
        self.db = db
    }

    func find(type: Recommendation.ItemType, dateString: String) async throws -> Recommendation? {
        try await db.dbQueue.read { db in
            try Recommendation
                .filter(Recommendation.Columns.itemType == type.rawValue)
                .filter(Recommendation.Columns.assignedDate == dateString)
                .fetchOne(db)
        }
    }

    func save(_ recommendation: Recommendation) async throws {
        try await db.dbQueue.write { db in
            var rec = recommendation
            try rec.insert(db)
        }
    }

    func update(type: Recommendation.ItemType, dateString: String, itemId: Int) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "UPDATE recommendations SET itemId = ? WHERE itemType = ? AND assignedDate = ?",
                arguments: [itemId, type.rawValue, dateString]
            )
        }
    }

    func delete(type: Recommendation.ItemType, dateString: String) async throws {
        try await db.dbQueue.write { db in
            try db.execute(
                sql: "DELETE FROM recommendations WHERE itemType = ? AND assignedDate = ?",
                arguments: [type.rawValue, dateString]
            )
        }
    }

    func deleteAll() async throws {
        try await db.dbQueue.write { db in
            try db.execute(sql: "DELETE FROM recommendations")
        }
    }
}
