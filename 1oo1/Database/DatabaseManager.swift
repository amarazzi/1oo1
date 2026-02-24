import Foundation
import GRDB

final class DatabaseManager {
    let dbQueue: DatabaseQueue

    init() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            // Migrate from old "1001Daily" folder if it exists
            let oldDir = appSupport.appendingPathComponent("1001Daily")
            let newDir = appSupport.appendingPathComponent("1oo1")
            if FileManager.default.fileExists(atPath: oldDir.path) && !FileManager.default.fileExists(atPath: newDir.path) {
                try? FileManager.default.moveItem(at: oldDir, to: newDir)
            }
            let dbDir = appSupport.appendingPathComponent("1oo1")
            try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
            let dbURL = dbDir.appendingPathComponent("db.sqlite")

            var config = Configuration()
            config.prepareDatabase { db in
                db.trace { print("SQL: \($0)") }
            }

            dbQueue = try DatabaseQueue(path: dbURL.path, configuration: config)
            try Self.runMigrations(dbQueue)
        } catch {
            fatalError("DatabaseManager init failed: \(error)")
        }
    }

    // In-memory init for tests and previews
    init(inMemory: Bool) {
        precondition(inMemory, "Use designated init for file-backed DB")
        do {
            dbQueue = try DatabaseQueue()
            try Self.runMigrations(dbQueue)
        } catch {
            fatalError("In-memory DB init failed: \(error)")
        }
    }

    static func runMigrations(_ db: DatabaseQueue) throws {
        var migrator = DatabaseMigrator()
        migrator.eraseDatabaseOnSchemaChange = false

        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "movies", ifNotExists: true) { t in
                t.primaryKey("id", .integer)
                t.column("title", .text).notNull()
                t.column("year", .integer).notNull()
                t.column("director", .text).notNull()
                t.column("genre", .text).notNull()
                t.column("tmdbId", .integer)
                t.column("imdbId", .text)
                t.column("overview", .text)
                t.column("runtimeMinutes", .integer)
                t.column("posterPath", .text)
            }

            try db.create(table: "albums", ifNotExists: true) { t in
                t.primaryKey("id", .integer)
                t.column("title", .text).notNull()
                t.column("year", .integer).notNull()
                t.column("artist", .text).notNull()
                t.column("genre", .text).notNull()
                t.column("musicbrainzId", .text)
                t.column("description", .text)
                t.column("coverArtPath", .text)
            }

            try db.create(table: "recommendations", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("itemId", .integer).notNull()
                t.column("itemType", .text).notNull()
                t.column("assignedDate", .text).notNull()
            }
            try db.create(
                indexOn: "recommendations",
                columns: ["assignedDate", "itemType"]
            )

            try db.create(table: "history", ifNotExists: true) { t in
                t.autoIncrementedPrimaryKey("id")
                t.column("itemId", .integer).notNull()
                t.column("itemType", .text).notNull()
                t.column("dateCompleted", .text).notNull()
                t.column("rating", .integer)
                t.column("notes", .text)
                t.column("title", .text).notNull()
                t.column("year", .integer).notNull()
                t.column("artist", .text)
                t.column("director", .text)
            }
            try db.create(
                indexOn: "history",
                columns: ["itemType"]
            )
        }

        // Migrate rating column from INTEGER to REAL to support half-star values
        migrator.registerMigration("v2_rating_real") { db in
            try db.execute(sql: """
                CREATE TABLE history_new (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    itemId INTEGER NOT NULL,
                    itemType TEXT NOT NULL,
                    dateCompleted TEXT NOT NULL,
                    rating REAL,
                    notes TEXT,
                    title TEXT NOT NULL,
                    year INTEGER NOT NULL,
                    artist TEXT,
                    director TEXT
                )
            """)
            try db.execute(sql: "INSERT INTO history_new SELECT * FROM history")
            try db.execute(sql: "DROP TABLE history")
            try db.execute(sql: "ALTER TABLE history_new RENAME TO history")
            try db.create(indexOn: "history", columns: ["itemType"])
        }

        // Add trailerYouTubeKey column to movies
        migrator.registerMigration("v3_trailer_key") { db in
            try db.alter(table: "movies") { t in
                t.add(column: "trailerYouTubeKey", .text)
            }
        }

        // Add tmdbRating column to movies
        migrator.registerMigration("v4_tmdb_rating") { db in
            try db.alter(table: "movies") { t in
                t.add(column: "tmdbRating", .double)
            }
        }

        try migrator.migrate(db)
    }
}
