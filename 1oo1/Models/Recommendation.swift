import Foundation
import GRDB

struct Recommendation: Codable, Identifiable, FetchableRecord, PersistableRecord {
    enum ItemType: String, Codable {
        case movie
        case album
    }

    var id: Int?
    var itemId: Int
    var itemType: ItemType
    var assignedDate: String  // ISO8601 date string "2026-02-21"

    static let databaseTableName = "recommendations"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let itemId = Column(CodingKeys.itemId)
        static let itemType = Column(CodingKeys.itemType)
        static let assignedDate = Column(CodingKeys.assignedDate)
    }
}

// MARK: - Date helpers
extension Recommendation {
    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
