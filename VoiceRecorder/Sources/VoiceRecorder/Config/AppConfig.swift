import Foundation

struct AppConfig: Codable {
    var recordHotkey: String
    var langHotkey: String
    var language: String
    var model: String

    enum CodingKeys: String, CodingKey {
        case recordHotkey = "record_hotkey"
        case langHotkey = "lang_hotkey"
        case language
        case model
        // Legacy key
        case hotkey
    }

    static let defaultConfig = AppConfig(
        recordHotkey: "ctrl+shift+m",
        langHotkey: "cmd+shift+space",
        language: "ko",
        model: "openai_whisper-large-v3_turbo"
    )

    static var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("voice-recorder")
    }

    static var configFilePath: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    init(recordHotkey: String, langHotkey: String, language: String, model: String) {
        self.recordHotkey = recordHotkey
        self.langHotkey = langHotkey
        self.language = language
        self.model = model
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = AppConfig.defaultConfig

        // Legacy migration: "hotkey" → "record_hotkey"
        let legacyHotkey = try container.decodeIfPresent(String.self, forKey: .hotkey)
        let recordHotkey = try container.decodeIfPresent(String.self, forKey: .recordHotkey)
        self.recordHotkey = recordHotkey ?? legacyHotkey ?? defaults.recordHotkey

        self.langHotkey = try container.decodeIfPresent(String.self, forKey: .langHotkey) ?? defaults.langHotkey
        self.language = try container.decodeIfPresent(String.self, forKey: .language) ?? defaults.language
        self.model = try container.decodeIfPresent(String.self, forKey: .model) ?? defaults.model
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordHotkey, forKey: .recordHotkey)
        try container.encode(langHotkey, forKey: .langHotkey)
        try container.encode(language, forKey: .language)
        try container.encode(model, forKey: .model)
    }

    static func load() -> AppConfig {
        let path = configFilePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return defaultConfig
        }
        do {
            let data = try Data(contentsOf: path)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
            // Ensure non-empty hotkeys
            var result = config
            if result.recordHotkey.isEmpty { result.recordHotkey = defaultConfig.recordHotkey }
            if result.langHotkey.isEmpty { result.langHotkey = defaultConfig.langHotkey }
            return result
        } catch {
            print("Failed to load config: \(error). Using defaults.")
            return defaultConfig
        }
    }

    func save() {
        let dir = AppConfig.configDirectory
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(self)
            try data.write(to: AppConfig.configFilePath)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
