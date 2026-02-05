import Foundation

public final class SharedConfig {
    public static let shared = SharedConfig()

    private let appGroupIdentifier = "group.com.clickup.widget"
    private let configFileName = "widget_config.json"

    private var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    private var configFileURL: URL? {
        containerURL?.appendingPathComponent(configFileName)
    }

    private init() {}

    public struct Config: Codable {
        public var teamId: String?
        public var userId: String?

        public init(teamId: String? = nil, userId: String? = nil) {
            self.teamId = teamId
            self.userId = userId
        }
    }

    public func save(teamId: String, userId: String) {
        guard let url = configFileURL else { return }
        let config = Config(teamId: teamId, userId: userId)
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: url, options: .atomic)
            // Remove quarantine attribute so widget extension can read it
            removeQuarantine(from: url)
        }
    }

    private func removeQuarantine(from url: URL) {
        let quarantineKey = "com.apple.quarantine"
        let provenanceKey = "com.apple.provenance"

        // Use removexattr to remove the quarantine attribute
        _ = url.withUnsafeFileSystemRepresentation { path in
            if let path = path {
                removexattr(path, quarantineKey, 0)
                removexattr(path, provenanceKey, 0)
            }
        }
    }

    public func load() -> Config? {
        guard let url = configFileURL,
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            return nil
        }
        return config
    }

    public func debugInfo() -> String {
        guard let url = containerURL else { return "NO_CONTAINER" }
        let fileURL = url.appendingPathComponent(configFileName)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let data = try? Data(contentsOf: fileURL) {
                return "OK:\(data.count)b"
            }
            return "FILE_UNREADABLE"
        }
        return "NO_FILE"
    }
}

final class AppStorage {
    static let shared = AppStorage()

    private let appGroupIdentifier = "group.com.clickup.widget"
    private let defaults: UserDefaults

    private enum Keys {
        static let selectedTeamID = "selectedTeamID"
        static let cachedTasks = "cachedTasks"
    }

    private init() {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with suite name: \(appGroupIdentifier)")
        }
        self.defaults = defaults
    }

    // MARK: - Selected Team ID

    var selectedTeamID: String? {
        get {
            defaults.string(forKey: Keys.selectedTeamID)
        }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Keys.selectedTeamID)
            } else {
                defaults.removeObject(forKey: Keys.selectedTeamID)
            }
        }
    }

    // MARK: - Cached Tasks

    var cachedTasks: [ClickUpTask] {
        get {
            guard let data = defaults.data(forKey: Keys.cachedTasks) else {
                return []
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([ClickUpTask].self, from: data)) ?? []
        }
        set {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let encoded = try? encoder.encode(newValue) {
                defaults.set(encoded, forKey: Keys.cachedTasks)
            }
        }
    }

    // MARK: - Convenience Methods

    func clearCache() {
        defaults.removeObject(forKey: Keys.cachedTasks)
    }

    func clearAll() {
        defaults.removeObject(forKey: Keys.selectedTeamID)
        defaults.removeObject(forKey: Keys.cachedTasks)
    }
}
