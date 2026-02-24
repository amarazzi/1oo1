import Foundation
import GRDB

struct HistoryEntry: Codable, Identifiable, FetchableRecord, PersistableRecord {
    enum ItemType: String, Codable {
        case movie
        case album
    }

    var id: Int?
    var itemId: Int
    var itemType: ItemType
    var dateCompleted: String  // ISO8601
    var rating: Double?        // 0.5–5.0
    var notes: String?
    var title: String
    var year: Int
    var artist: String?
    var director: String?

    static let databaseTableName = "history"

    enum Columns {
        static let id = Column(CodingKeys.id)
        static let itemId = Column(CodingKeys.itemId)
        static let itemType = Column(CodingKeys.itemType)
        static let dateCompleted = Column(CodingKeys.dateCompleted)
        static let rating = Column(CodingKeys.rating)
        static let notes = Column(CodingKeys.notes)
        static let title = Column(CodingKeys.title)
        static let year = Column(CodingKeys.year)
        static let artist = Column(CodingKeys.artist)
        static let director = Column(CodingKeys.director)
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateCompleted) else { return dateCompleted }
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
