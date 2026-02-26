import Foundation

struct AppConfig: Codable, ConfigStoring {
    var recordHotkey: String
    var langHotkey: String
    var language: String
    var model: String
    var overlayPosition: String
    var saveDebugAudioFile: Bool

    enum CodingKeys: String, CodingKey {
        case recordHotkey = "record_hotkey"
        case langHotkey = "lang_hotkey"
        case language
        case model
        case overlayPosition = "overlay_position"
        case saveDebugAudioFile = "save_debug_audio_file"
        // Legacy key
        case hotkey
    }

    static let defaultConfig = AppConfig(
        recordHotkey: "ctrl+shift+m",
        langHotkey: "cmd+shift+space",
        language: "ko",
        model: "openai_whisper-large-v3_turbo",
        overlayPosition: "bottom",
        saveDebugAudioFile: false
    )

    static var configDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config")
            .appendingPathComponent("voice-recorder")
    }

    static var configFilePath: URL {
        configDirectory.appendingPathComponent("config.json")
    }

    init(
        recordHotkey: String,
        langHotkey: String,
        language: String,
        model: String,
        overlayPosition: String,
        saveDebugAudioFile: Bool
    ) {
        self.recordHotkey = recordHotkey
        self.langHotkey = langHotkey
        self.language = language
        self.model = model
        self.overlayPosition = overlayPosition
        self.saveDebugAudioFile = saveDebugAudioFile
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
        self.overlayPosition = try container.decodeIfPresent(String.self, forKey: .overlayPosition) ?? defaults.overlayPosition
        self.saveDebugAudioFile = try container.decodeIfPresent(Bool.self, forKey: .saveDebugAudioFile) ?? defaults.saveDebugAudioFile
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(recordHotkey, forKey: .recordHotkey)
        try container.encode(langHotkey, forKey: .langHotkey)
        try container.encode(language, forKey: .language)
        try container.encode(model, forKey: .model)
        try container.encode(overlayPosition, forKey: .overlayPosition)
        try container.encode(saveDebugAudioFile, forKey: .saveDebugAudioFile)
    }

    static func load() -> AppConfig {
        let path = configFilePath
        guard FileManager.default.fileExists(atPath: path.path) else {
            return defaultConfig
        }
        do {
            let data = try Data(contentsOf: path)
            let config = try JSONDecoder().decode(AppConfig.self, from: data)
        var result = config
        if result.recordHotkey.isEmpty { result.recordHotkey = defaultConfig.recordHotkey }
        if result.langHotkey.isEmpty { result.langHotkey = defaultConfig.langHotkey }
        if result.overlayPosition.isEmpty { result.overlayPosition = defaultConfig.overlayPosition }
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
