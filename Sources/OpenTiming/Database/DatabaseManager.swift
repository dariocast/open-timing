import Foundation
import SQLite3

public final class DatabaseManager: @unchecked Sendable {
    public static let shared = DatabaseManager()
    
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.opentiming.database", qos: .userInitiated)
    
    public init(databasePath: String? = nil) {
        let path: String
        if let databasePath = databasePath {
            path = databasePath
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("OpenTiming", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            path = dir.appendingPathComponent("opetiming.sqlite").path
        }
        
        openDatabase(at: path)
        createTables()
        seedDefaultsIfNeeded()
    }
    
    deinit {
        if db != nil {
            sqlite3_close(db)
        }
    }
    
    // MARK: - Open & Init
    
    private func openDatabase(at path: String) {
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX, nil) != SQLITE_OK {
            let errMsg = String(cString: sqlite3_errmsg(db))
            print("Failed to open database at \(path): \(errMsg)")
        } else {
            // Enable WAL mode for high concurrent read/write performance
            sqlite3_exec(db, "PRAGMA journal_mode = WAL;", nil, nil, nil)
            sqlite3_exec(db, "PRAGMA synchronous = NORMAL;", nil, nil, nil)
        }
    }
    
    private func createTables() {
        queue.sync {
            let categoriesSQL = """
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                color_hex TEXT NOT NULL,
                icon_name TEXT NOT NULL,
                productivity_score INTEGER NOT NULL DEFAULT 0,
                is_default INTEGER NOT NULL DEFAULT 0,
                sort_order INTEGER NOT NULL DEFAULT 0
            );
            """
            
            let projectsSQL = """
            CREATE TABLE IF NOT EXISTS projects (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                category_id TEXT,
                color_hex TEXT NOT NULL,
                icon_name TEXT NOT NULL,
                is_archived INTEGER NOT NULL DEFAULT 0,
                hourly_rate REAL,
                created_at REAL NOT NULL,
                FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
            );
            """
            
            let rulesSQL = """
            CREATE TABLE IF NOT EXISTS rules (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                target_field TEXT NOT NULL,
                match_type TEXT NOT NULL,
                pattern TEXT NOT NULL,
                target_category_id TEXT,
                target_project_id TEXT,
                priority INTEGER NOT NULL DEFAULT 0,
                is_enabled INTEGER NOT NULL DEFAULT 1,
                FOREIGN KEY(target_category_id) REFERENCES categories(id) ON DELETE SET NULL,
                FOREIGN KEY(target_project_id) REFERENCES projects(id) ON DELETE SET NULL
            );
            """
            
            let activitiesSQL = """
            CREATE TABLE IF NOT EXISTS activity_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                app_name TEXT NOT NULL,
                bundle_identifier TEXT NOT NULL,
                window_title TEXT NOT NULL,
                url TEXT,
                domain TEXT,
                start_date REAL NOT NULL,
                end_date REAL NOT NULL,
                duration REAL NOT NULL,
                category_id TEXT,
                project_id TEXT,
                is_idle INTEGER NOT NULL DEFAULT 0,
                created_at REAL NOT NULL,
                FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL,
                FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE SET NULL
            );
            
            CREATE INDEX IF NOT EXISTS idx_activity_dates ON activity_records (start_date, end_date);
            CREATE INDEX IF NOT EXISTS idx_activity_bundle ON activity_records (bundle_identifier);
            CREATE INDEX IF NOT EXISTS idx_activity_category ON activity_records (category_id);
            CREATE INDEX IF NOT EXISTS idx_activity_project ON activity_records (project_id);
            """
            
            _ = execute(sql: categoriesSQL)
            _ = execute(sql: projectsSQL)
            _ = execute(sql: rulesSQL)
            _ = execute(sql: activitiesSQL)
        }
    }
    
    private func execute(sql: String) -> Bool {
        var err: UnsafeMutablePointer<CChar>?
        if sqlite3_exec(db, sql, nil, nil, &err) != SQLITE_OK {
            if let err = err {
                print("SQLite error: \(String(cString: err)) in SQL: \(sql)")
                sqlite3_free(err)
            }
            return false
        }
        return true
    }
    
    // MARK: - Defaults Seeding
    
    private func seedDefaultsIfNeeded() {
        let cats = getCategories()
        if cats.isEmpty {
            let devId = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
            let designId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
            let commId = UUID(uuidString: "33333333-3333-3333-3333-333333333333")!
            let docId = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
            let entId = UUID(uuidString: "55555555-5555-5555-5555-555555555555")!
            let utilId = UUID(uuidString: "66666666-6666-6666-6666-666666666666")!
            
            let defaultCategories: [ActivityCategory] = [
                ActivityCategory(id: devId, name: "Development", colorHex: "#0A84FF", iconName: "chevron.left.forwardslash.chevron.right", productivityScore: 2, isDefault: true, sortOrder: 0),
                ActivityCategory(id: designId, name: "Design & Creative", colorHex: "#BF5AF2", iconName: "paintpalette.fill", productivityScore: 2, isDefault: true, sortOrder: 1),
                ActivityCategory(id: docId, name: "Writing & Docs", colorHex: "#5E5CE6", iconName: "doc.text.fill", productivityScore: 1, isDefault: true, sortOrder: 2),
                ActivityCategory(id: commId, name: "Communication", colorHex: "#30D158", iconName: "bubble.left.and.bubble.right.fill", productivityScore: 0, isDefault: true, sortOrder: 3),
                ActivityCategory(id: utilId, name: "Utilities & System", colorHex: "#8E8E93", iconName: "gearshape.fill", productivityScore: 0, isDefault: true, sortOrder: 4),
                ActivityCategory(id: entId, name: "Entertainment & Social", colorHex: "#FF453A", iconName: "tv.fill", productivityScore: -2, isDefault: true, sortOrder: 5)
            ]
            
            for cat in defaultCategories {
                saveCategory(cat)
            }
            
            let defaultRules: [TrackingRule] = [
                // Development
                TrackingRule(name: "Xcode", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.apple.dt.Xcode", targetCategoryId: devId, priority: 10),
                TrackingRule(name: "Visual Studio Code", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.microsoft.VSCode", targetCategoryId: devId, priority: 10),
                TrackingRule(name: "Cursor", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.todesktop.230313mzl4w4u92", targetCategoryId: devId, priority: 10),
                TrackingRule(name: "Zed", targetField: .bundleIdentifier, matchType: .contains, pattern: "dev.zed.Zed", targetCategoryId: devId, priority: 10),
                TrackingRule(name: "Terminal & iTerm", targetField: .bundleIdentifier, matchType: .regex, pattern: "com\\.apple\\.Terminal|com\\.googlecode\\.iterm2", targetCategoryId: devId, priority: 10),
                TrackingRule(name: "GitHub / GitLab", targetField: .domain, matchType: .regex, pattern: "github\\.com|gitlab\\.com", targetCategoryId: devId, priority: 8),
                TrackingRule(name: "Stack Overflow", targetField: .domain, matchType: .contains, pattern: "stackoverflow.com", targetCategoryId: devId, priority: 8),
                
                // Design
                TrackingRule(name: "Figma", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.figma.Desktop", targetCategoryId: designId, priority: 10),
                TrackingRule(name: "Figma Web", targetField: .domain, matchType: .contains, pattern: "figma.com", targetCategoryId: designId, priority: 8),
                TrackingRule(name: "Sketch", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.bohemiancoding.sketch3", targetCategoryId: designId, priority: 10),
                TrackingRule(name: "Photoshop & Illustrator", targetField: .bundleIdentifier, matchType: .regex, pattern: "com\\.adobe\\.Photoshop|com\\.adobe\\.illustrator", targetCategoryId: designId, priority: 10),
                
                // Writing & Docs
                TrackingRule(name: "Notion", targetField: .bundleIdentifier, matchType: .contains, pattern: "notion.id", targetCategoryId: docId, priority: 10),
                TrackingRule(name: "Obsidian", targetField: .bundleIdentifier, matchType: .contains, pattern: "md.obsidian", targetCategoryId: docId, priority: 10),
                TrackingRule(name: "Google Docs", targetField: .domain, matchType: .contains, pattern: "docs.google.com", targetCategoryId: docId, priority: 8),
                
                // Communication
                TrackingRule(name: "Slack", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.tinyspeck.slackmacgap", targetCategoryId: commId, priority: 10),
                TrackingRule(name: "Discord", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.hnc.Discord", targetCategoryId: commId, priority: 10),
                TrackingRule(name: "Mail & Messages", targetField: .bundleIdentifier, matchType: .regex, pattern: "com\\.apple\\.mail|com\\.apple\\.MobileSMS", targetCategoryId: commId, priority: 10),
                TrackingRule(name: "Telegram & WhatsApp", targetField: .bundleIdentifier, matchType: .regex, pattern: "ru\\.keepcoder\\.Telegram|net\\.whatsapp\\.WhatsApp", targetCategoryId: commId, priority: 10),
                
                // Entertainment
                TrackingRule(name: "YouTube", targetField: .domain, matchType: .contains, pattern: "youtube.com", targetCategoryId: entId, priority: 10),
                TrackingRule(name: "Netflix", targetField: .domain, matchType: .contains, pattern: "netflix.com", targetCategoryId: entId, priority: 10),
                TrackingRule(name: "Reddit", targetField: .domain, matchType: .contains, pattern: "reddit.com", targetCategoryId: entId, priority: 10),
                TrackingRule(name: "Twitter / X", targetField: .domain, matchType: .regex, pattern: "twitter\\.com|x\\.com", targetCategoryId: entId, priority: 10),
                TrackingRule(name: "Spotify", targetField: .bundleIdentifier, matchType: .contains, pattern: "com.spotify.client", targetCategoryId: entId, priority: 5)
            ]
            
            for rule in defaultRules {
                saveRule(rule)
            }
        }
    }
    
    // MARK: - Category Operations
    
    public func getCategories() -> [ActivityCategory] {
        queue.sync {
            var categories: [ActivityCategory] = []
            let sql = "SELECT id, name, color_hex, icon_name, productivity_score, is_default, sort_order FROM categories ORDER BY sort_order ASC, name ASC;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let idStr = String(cString: sqlite3_column_text(stmt, 0))
                    let name = String(cString: sqlite3_column_text(stmt, 1))
                    let colorHex = String(cString: sqlite3_column_text(stmt, 2))
                    let iconName = String(cString: sqlite3_column_text(stmt, 3))
                    let prod = Int(sqlite3_column_int(stmt, 4))
                    let isDef = sqlite3_column_int(stmt, 5) != 0
                    let sort = Int(sqlite3_column_int(stmt, 6))
                    
                    if let id = UUID(uuidString: idStr) {
                        categories.append(ActivityCategory(
                            id: id,
                            name: name,
                            colorHex: colorHex,
                            iconName: iconName,
                            productivityScore: prod,
                            isDefault: isDef,
                            sortOrder: sort
                        ))
                    }
                }
            }
            sqlite3_finalize(stmt)
            return categories
        }
    }
    
    public func saveCategory(_ category: ActivityCategory) {
        queue.sync {
            let sql = """
            INSERT INTO categories (id, name, color_hex, icon_name, productivity_score, is_default, sort_order)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name,
                color_hex = excluded.color_hex,
                icon_name = excluded.icon_name,
                productivity_score = excluded.productivity_score,
                is_default = excluded.is_default,
                sort_order = excluded.sort_order;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, category.id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, category.name, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 3, category.colorHex, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 4, category.iconName, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(stmt, 5, Int32(category.productivityScore))
                sqlite3_bind_int(stmt, 6, category.isDefault ? 1 : 0)
                sqlite3_bind_int(stmt, 7, Int32(category.sortOrder))
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func deleteCategory(id: UUID) {
        queue.sync {
            let sql = "DELETE FROM categories WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    // MARK: - Project Operations
    
    public func getProjects() -> [Project] {
        queue.sync {
            var projects: [Project] = []
            let sql = "SELECT id, name, category_id, color_hex, icon_name, is_archived, hourly_rate, created_at FROM projects ORDER BY name ASC;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let idStr = String(cString: sqlite3_column_text(stmt, 0))
                    let name = String(cString: sqlite3_column_text(stmt, 1))
                    var catId: UUID?
                    if let cText = sqlite3_column_text(stmt, 2) {
                        catId = UUID(uuidString: String(cString: cText))
                    }
                    let colorHex = String(cString: sqlite3_column_text(stmt, 3))
                    let iconName = String(cString: sqlite3_column_text(stmt, 4))
                    let isArch = sqlite3_column_int(stmt, 5) != 0
                    var rate: Double?
                    if sqlite3_column_type(stmt, 6) != SQLITE_NULL {
                        rate = sqlite3_column_double(stmt, 6)
                    }
                    let created = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 7))
                    
                    if let id = UUID(uuidString: idStr) {
                        projects.append(Project(
                            id: id,
                            name: name,
                            categoryId: catId,
                            colorHex: colorHex,
                            iconName: iconName,
                            isArchived: isArch,
                            hourlyRate: rate,
                            createdAt: created
                        ))
                    }
                }
            }
            sqlite3_finalize(stmt)
            return projects
        }
    }
    
    public func saveProject(_ project: Project) {
        queue.sync {
            let sql = """
            INSERT INTO projects (id, name, category_id, color_hex, icon_name, is_archived, hourly_rate, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name,
                category_id = excluded.category_id,
                color_hex = excluded.color_hex,
                icon_name = excluded.icon_name,
                is_archived = excluded.is_archived,
                hourly_rate = excluded.hourly_rate;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, project.id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, project.name, -1, SQLITE_TRANSIENT)
                if let catId = project.categoryId {
                    sqlite3_bind_text(stmt, 3, catId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 3)
                }
                sqlite3_bind_text(stmt, 4, project.colorHex, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 5, project.iconName, -1, SQLITE_TRANSIENT)
                sqlite3_bind_int(stmt, 6, project.isArchived ? 1 : 0)
                if let rate = project.hourlyRate {
                    sqlite3_bind_double(stmt, 7, rate)
                } else {
                    sqlite3_bind_null(stmt, 7)
                }
                sqlite3_bind_double(stmt, 8, project.createdAt.timeIntervalSince1970)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func deleteProject(id: UUID) {
        queue.sync {
            let sql = "DELETE FROM projects WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    // MARK: - Rule Operations
    
    public func getRules() -> [TrackingRule] {
        queue.sync {
            var rules: [TrackingRule] = []
            let sql = "SELECT id, name, target_field, match_type, pattern, target_category_id, target_project_id, priority, is_enabled FROM rules ORDER BY priority DESC, name ASC;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let idStr = String(cString: sqlite3_column_text(stmt, 0))
                    let name = String(cString: sqlite3_column_text(stmt, 1))
                    let fieldStr = String(cString: sqlite3_column_text(stmt, 2))
                    let matchStr = String(cString: sqlite3_column_text(stmt, 3))
                    let pattern = String(cString: sqlite3_column_text(stmt, 4))
                    var catId: UUID?
                    if let cText = sqlite3_column_text(stmt, 5) {
                        catId = UUID(uuidString: String(cString: cText))
                    }
                    var projId: UUID?
                    if let pText = sqlite3_column_text(stmt, 6) {
                        projId = UUID(uuidString: String(cString: pText))
                    }
                    let priority = Int(sqlite3_column_int(stmt, 7))
                    let isEnabled = sqlite3_column_int(stmt, 8) != 0
                    
                    if let id = UUID(uuidString: idStr),
                       let field = RuleField(rawValue: fieldStr),
                       let match = RuleMatchType(rawValue: matchStr) {
                        rules.append(TrackingRule(
                            id: id,
                            name: name,
                            targetField: field,
                            matchType: match,
                            pattern: pattern,
                            targetCategoryId: catId,
                            targetProjectId: projId,
                            priority: priority,
                            isEnabled: isEnabled
                        ))
                    }
                }
            }
            sqlite3_finalize(stmt)
            return rules
        }
    }
    
    public func saveRule(_ rule: TrackingRule) {
        queue.sync {
            let sql = """
            INSERT INTO rules (id, name, target_field, match_type, pattern, target_category_id, target_project_id, priority, is_enabled)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                name = excluded.name,
                target_field = excluded.target_field,
                match_type = excluded.match_type,
                pattern = excluded.pattern,
                target_category_id = excluded.target_category_id,
                target_project_id = excluded.target_project_id,
                priority = excluded.priority,
                is_enabled = excluded.is_enabled;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, rule.id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, rule.name, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 3, rule.targetField.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 4, rule.matchType.rawValue, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 5, rule.pattern, -1, SQLITE_TRANSIENT)
                if let catId = rule.targetCategoryId {
                    sqlite3_bind_text(stmt, 6, catId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 6)
                }
                if let projId = rule.targetProjectId {
                    sqlite3_bind_text(stmt, 7, projId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 7)
                }
                sqlite3_bind_int(stmt, 8, Int32(rule.priority))
                sqlite3_bind_int(stmt, 9, rule.isEnabled ? 1 : 0)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func deleteRule(id: UUID) {
        queue.sync {
            let sql = "DELETE FROM rules WHERE id = ?;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, id.uuidString, -1, SQLITE_TRANSIENT)
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    // MARK: - Activity Record Operations
    
    @discardableResult
    public func insertActivityRecord(_ record: ActivityRecord) -> Int64? {
        queue.sync {
            let sql = """
            INSERT INTO activity_records (app_name, bundle_identifier, window_title, url, domain, start_date, end_date, duration, category_id, project_id, is_idle, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
            """
            var stmt: OpaquePointer?
            var insertedId: Int64?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, record.appName, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, record.bundleIdentifier, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 3, record.windowTitle, -1, SQLITE_TRANSIENT)
                if let url = record.url {
                    sqlite3_bind_text(stmt, 4, url, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 4)
                }
                if let domain = record.domain {
                    sqlite3_bind_text(stmt, 5, domain, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 5)
                }
                sqlite3_bind_double(stmt, 6, record.startDate.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 7, record.endDate.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 8, record.duration)
                if let catId = record.categoryId {
                    sqlite3_bind_text(stmt, 9, catId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 9)
                }
                if let projId = record.projectId {
                    sqlite3_bind_text(stmt, 10, projId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 10)
                }
                sqlite3_bind_int(stmt, 11, record.isIdle ? 1 : 0)
                sqlite3_bind_double(stmt, 12, record.createdAt.timeIntervalSince1970)
                
                if sqlite3_step(stmt) == SQLITE_DONE {
                    insertedId = sqlite3_last_insert_rowid(db)
                }
            }
            sqlite3_finalize(stmt)
            return insertedId
        }
    }
    
    public func updateActivityRecord(_ record: ActivityRecord) {
        guard let id = record.id else { return }
        queue.sync {
            let sql = """
            UPDATE activity_records SET
                app_name = ?,
                bundle_identifier = ?,
                window_title = ?,
                url = ?,
                domain = ?,
                start_date = ?,
                end_date = ?,
                duration = ?,
                category_id = ?,
                project_id = ?,
                is_idle = ?
            WHERE id = ?;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_text(stmt, 1, record.appName, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 2, record.bundleIdentifier, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(stmt, 3, record.windowTitle, -1, SQLITE_TRANSIENT)
                if let url = record.url {
                    sqlite3_bind_text(stmt, 4, url, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 4)
                }
                if let domain = record.domain {
                    sqlite3_bind_text(stmt, 5, domain, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 5)
                }
                sqlite3_bind_double(stmt, 6, record.startDate.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 7, record.endDate.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 8, record.duration)
                if let catId = record.categoryId {
                    sqlite3_bind_text(stmt, 9, catId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 9)
                }
                if let projId = record.projectId {
                    sqlite3_bind_text(stmt, 10, projId.uuidString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, 10)
                }
                sqlite3_bind_int(stmt, 11, record.isIdle ? 1 : 0)
                sqlite3_bind_int64(stmt, 12, id)
                
                sqlite3_step(stmt)
            }
            sqlite3_finalize(stmt)
        }
    }
    
    public func getActivities(from startDate: Date, to endDate: Date) -> [ActivityRecord] {
        queue.sync {
            var records: [ActivityRecord] = []
            let sql = """
            SELECT id, app_name, bundle_identifier, window_title, url, domain, start_date, end_date, duration, category_id, project_id, is_idle, created_at
            FROM activity_records
            WHERE end_date >= ? AND start_date <= ?
            ORDER BY start_date ASC;
            """
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                sqlite3_bind_double(stmt, 1, startDate.timeIntervalSince1970)
                sqlite3_bind_double(stmt, 2, endDate.timeIntervalSince1970)
                
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = sqlite3_column_int64(stmt, 0)
                    let appName = String(cString: sqlite3_column_text(stmt, 1))
                    let bundleId = String(cString: sqlite3_column_text(stmt, 2))
                    let winTitle = String(cString: sqlite3_column_text(stmt, 3))
                    var url: String?
                    if let uText = sqlite3_column_text(stmt, 4) {
                        url = String(cString: uText)
                    }
                    var domain: String?
                    if let dText = sqlite3_column_text(stmt, 5) {
                        domain = String(cString: dText)
                    }
                    let sDate = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 6))
                    let eDate = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 7))
                    let duration = sqlite3_column_double(stmt, 8)
                    var catId: UUID?
                    if let cText = sqlite3_column_text(stmt, 9) {
                        catId = UUID(uuidString: String(cString: cText))
                    }
                    var projId: UUID?
                    if let pText = sqlite3_column_text(stmt, 10) {
                        projId = UUID(uuidString: String(cString: pText))
                    }
                    let isIdle = sqlite3_column_int(stmt, 11) != 0
                    let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(stmt, 12))
                    
                    records.append(ActivityRecord(
                        id: id,
                        appName: appName,
                        bundleIdentifier: bundleId,
                        windowTitle: winTitle,
                        url: url,
                        domain: domain,
                        startDate: sDate,
                        endDate: eDate,
                        duration: duration,
                        categoryId: catId,
                        projectId: projId,
                        isIdle: isIdle,
                        createdAt: createdAt
                    ))
                }
            }
            sqlite3_finalize(stmt)
            return records
        }
    }
    
    // MARK: - Aggregations & Statistics
    
    public func getStats(from startDate: Date, to endDate: Date) -> ActivityStats {
        let activities = getActivities(from: startDate, to: endDate)
        let categories = Dictionary(uniqueKeysWithValues: getCategories().map { ($0.id, $0) })
        let projects = Dictionary(uniqueKeysWithValues: getProjects().map { ($0.id, $0) })
        
        var totalActiveTime: TimeInterval = 0
        var totalIdleTime: TimeInterval = 0
        var productiveTime: TimeInterval = 0
        var neutralTime: TimeInterval = 0
        var distractingTime: TimeInterval = 0
        
        var appTimes: [String: (name: String, duration: TimeInterval, categoryId: UUID?)] = [:]
        var categoryTimes: [UUID?: TimeInterval] = [:]
        var projectTimes: [UUID: TimeInterval] = [:]
        
        // 24 Hourly buckets
        var hourlyBuckets = [Int: (prod: TimeInterval, dist: TimeInterval, neut: TimeInterval, total: TimeInterval)]()
        for h in 0..<24 {
            hourlyBuckets[h] = (0, 0, 0, 0)
        }
        
        let calendar = Calendar.current
        
        for act in activities {
            if act.isIdle {
                totalIdleTime += act.duration
                continue
            }
            
            totalActiveTime += act.duration
            
            // App aggregation
            if let existing = appTimes[act.bundleIdentifier] {
                appTimes[act.bundleIdentifier] = (existing.name, existing.duration + act.duration, act.categoryId ?? existing.categoryId)
            } else {
                appTimes[act.bundleIdentifier] = (act.appName, act.duration, act.categoryId)
            }
            
            // Category aggregation
            categoryTimes[act.categoryId, default: 0] += act.duration
            
            // Project aggregation
            if let pid = act.projectId {
                projectTimes[pid, default: 0] += act.duration
            }
            
            // Productivity calculation
            let prodScore = act.categoryId.flatMap { categories[$0]?.productivityScore } ?? 0
            if prodScore > 0 {
                productiveTime += act.duration
            } else if prodScore < 0 {
                distractingTime += act.duration
            } else {
                neutralTime += act.duration
            }
            
            // Hourly breakdown
            let hour = calendar.component(.hour, from: act.startDate)
            if var currentHour = hourlyBuckets[hour] {
                currentHour.total += act.duration
                if prodScore > 0 {
                    currentHour.prod += act.duration
                } else if prodScore < 0 {
                    currentHour.dist += act.duration
                } else {
                    currentHour.neut += act.duration
                }
                hourlyBuckets[hour] = currentHour
            }
        }
        
        // Productivity score: 0% to 100%
        let score: Double
        if totalActiveTime > 0 {
            // (Productive + 0.5 * Neutral) / Total
            score = min(100, max(0, ((productiveTime + (neutralTime * 0.5)) / totalActiveTime) * 100.0))
        } else {
            score = 0
        }
        
        // Build App Breakdowns
        let appBreakdown: [AppTimeBreakdown] = appTimes.map { bundleId, val in
            let catColor = val.categoryId.flatMap { categories[$0]?.colorHex }
            let pct = totalActiveTime > 0 ? (val.duration / totalActiveTime) * 100.0 : 0
            return AppTimeBreakdown(
                appName: val.name,
                bundleIdentifier: bundleId,
                totalDuration: val.duration,
                percentage: pct,
                categoryId: val.categoryId,
                categoryColorHex: catColor
            )
        }.sorted(by: { $0.totalDuration > $1.totalDuration })
        
        // Build Category Breakdowns
        let categoryBreakdown: [CategoryTimeBreakdown] = categoryTimes.map { catId, dur in
            let cat = catId.flatMap { categories[$0] }
            let name = cat?.name ?? "Uncategorized"
            let color = cat?.colorHex ?? "#FF9500"
            let icon = cat?.iconName ?? "questionmark.circle"
            let prod = cat?.productivityScore ?? 0
            let pct = totalActiveTime > 0 ? (dur / totalActiveTime) * 100.0 : 0
            return CategoryTimeBreakdown(
                categoryId: catId,
                name: name,
                colorHex: color,
                iconName: icon,
                totalDuration: dur,
                percentage: pct,
                productivityScore: prod
            )
        }.sorted(by: { $0.totalDuration > $1.totalDuration })
        
        // Build Project Breakdowns
        let projectBreakdown: [ProjectTimeBreakdown] = projectTimes.compactMap { pid, dur in
            guard let proj = projects[pid] else { return nil }
            let pct = totalActiveTime > 0 ? (dur / totalActiveTime) * 100.0 : 0
            return ProjectTimeBreakdown(
                projectId: pid,
                name: proj.name,
                colorHex: proj.colorHex,
                totalDuration: dur,
                percentage: pct
            )
        }.sorted(by: { $0.totalDuration > $1.totalDuration })
        
        // Build Hourly Breakdown
        let hourlyBreakdown: [HourlyTimeBreakdown] = (0..<24).map { h in
            let b = hourlyBuckets[h] ?? (0, 0, 0, 0)
            let hourDate = calendar.date(bySettingHour: h, minute: 0, second: 0, of: startDate) ?? startDate
            return HourlyTimeBreakdown(
                hour: h,
                date: hourDate,
                totalDuration: b.total,
                productiveDuration: b.prod,
                distractingDuration: b.dist,
                neutralDuration: b.neut
            )
        }
        
        return ActivityStats(
            totalTime: totalActiveTime,
            productiveTime: productiveTime,
            neutralTime: neutralTime,
            distractingTime: distractingTime,
            idleTime: totalIdleTime,
            productivityScore: score,
            appBreakdown: appBreakdown,
            categoryBreakdown: categoryBreakdown,
            projectBreakdown: projectBreakdown,
            hourlyBreakdown: hourlyBreakdown
        )
    }
    
    // MARK: - Retroactive Rule Engine Application
    
    public func applyRulesToAllHistory(rules: [TrackingRule]) -> Int {
        return queue.sync {
            var updatedCount = 0
            let sql = "SELECT id, app_name, bundle_identifier, window_title, url, domain FROM activity_records;"
            var stmt: OpaquePointer?
            var updates: [(id: Int64, categoryId: UUID?, projectId: UUID?)] = []
            
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                while sqlite3_step(stmt) == SQLITE_ROW {
                    let id = sqlite3_column_int64(stmt, 0)
                    let appName = String(cString: sqlite3_column_text(stmt, 1))
                    let bundleId = String(cString: sqlite3_column_text(stmt, 2))
                    let winTitle = String(cString: sqlite3_column_text(stmt, 3))
                    var url: String?
                    if let uText = sqlite3_column_text(stmt, 4) {
                        url = String(cString: uText)
                    }
                    var domain: String?
                    if let dText = sqlite3_column_text(stmt, 5) {
                        domain = String(cString: dText)
                    }
                    
                    for rule in rules where rule.isEnabled {
                        if rule.matches(appName: appName, bundleIdentifier: bundleId, windowTitle: winTitle, domain: domain, url: url) {
                            updates.append((id: id, categoryId: rule.targetCategoryId, projectId: rule.targetProjectId))
                            break
                        }
                    }
                }
            }
            sqlite3_finalize(stmt)
            
            let updateSQL = "UPDATE activity_records SET category_id = ?, project_id = ? WHERE id = ?;"
            var updateStmt: OpaquePointer?
            if sqlite3_prepare_v2(db, updateSQL, -1, &updateStmt, nil) == SQLITE_OK {
                _ = execute(sql: "BEGIN TRANSACTION;")
                for item in updates {
                    if let catId = item.categoryId {
                        sqlite3_bind_text(updateStmt, 1, catId.uuidString, -1, SQLITE_TRANSIENT)
                    } else {
                        sqlite3_bind_null(updateStmt, 1)
                    }
                    if let projId = item.projectId {
                        sqlite3_bind_text(updateStmt, 2, projId.uuidString, -1, SQLITE_TRANSIENT)
                    } else {
                        sqlite3_bind_null(updateStmt, 2)
                    }
                    sqlite3_bind_int64(updateStmt, 3, item.id)
                    if sqlite3_step(updateStmt) == SQLITE_DONE {
                        updatedCount += 1
                    }
                    sqlite3_reset(updateStmt)
                }
                _ = execute(sql: "COMMIT;")
            }
            sqlite3_finalize(updateStmt)
            
            return updatedCount
        }
    }
    
    // MARK: - Export Data
    
    public func exportActivitiesJSON(from: Date, to: Date) -> Data? {
        let activities = getActivities(from: from, to: to)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(activities)
    }
    
    public func exportActivitiesCSV(from: Date, to: Date) -> String {
        let activities = getActivities(from: from, to: to)
        let categories = Dictionary(uniqueKeysWithValues: getCategories().map { ($0.id, $0.name) })
        let projects = Dictionary(uniqueKeysWithValues: getProjects().map { ($0.id, $0.name) })
        
        var csv = "ID,App Name,Bundle ID,Window Title,Domain,URL,Start Time,End Time,Duration (s),Category,Project,Is Idle\n"
        let formatter = ISO8601DateFormatter()
        
        for a in activities {
            let catName = a.categoryId.flatMap { categories[$0] } ?? ""
            let projName = a.projectId.flatMap { projects[$0] } ?? ""
            let titleEsc = "\"\(a.windowTitle.replacingOccurrences(of: "\"", with: "\"\""))\""
            let appEsc = "\"\(a.appName.replacingOccurrences(of: "\"", with: "\"\""))\""
            let urlEsc = "\"\(a.url?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
            let domainEsc = "\"\(a.domain ?? "")\""
            let sDate = formatter.string(from: a.startDate)
            let eDate = formatter.string(from: a.endDate)
            
            csv += "\(a.id ?? 0),\(appEsc),\(a.bundleIdentifier),\(titleEsc),\(domainEsc),\(urlEsc),\(sDate),\(eDate),\(Int(a.duration)),\"\(catName)\",\"\(projName)\",\(a.isIdle ? 1 : 0)\n"
        }
        return csv
    }
    
    public func clearAllActivities() {
        queue.sync {
            _ = execute(sql: "DELETE FROM activity_records;")
            _ = execute(sql: "VACUUM;")
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
