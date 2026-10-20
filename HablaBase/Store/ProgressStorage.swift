import Foundation

/// Where the learner's progress lives. Today it is a file on the phone; a cloud backend
/// (for accounts and several devices) can implement the same two calls later.
protocol ProgressStorage {
    func load() -> SavedState?
    func save(_ state: SavedState)
}

/// Saves progress as JSON in Application Support, which iOS keeps across app updates
/// and includes in the phone's iCloud/computer backups.
struct FileProgressStorage: ProgressStorage {
    /// Version 0.1 kept progress in UserDefaults; it is moved over on first launch.
    private static let legacyDefaultsKey = "hablabase.state.v1"

    let url: URL

    init(url: URL = FileProgressStorage.defaultURL) {
        self.url = url
    }

    static var defaultURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HablaBase", isDirectory: true)
        return folder.appendingPathComponent("progress.json")
    }

    func load() -> SavedState? {
        if let data = try? Data(contentsOf: url) {
            return try? JSONDecoder().decode(SavedState.self, from: data)
        }
        if let data = UserDefaults.standard.data(forKey: Self.legacyDefaultsKey),
           let legacy = try? JSONDecoder().decode(SavedState.self, from: data) {
            save(legacy)
            UserDefaults.standard.removeObject(forKey: Self.legacyDefaultsKey)
            return legacy
        }
        return nil
    }

    func save(_ state: SavedState) {
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(state)
            try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            assertionFailure("Could not save progress: \(error)")
        }
    }
}

/// Keeps progress in memory only; used by tests and previews.
final class InMemoryProgressStorage: ProgressStorage {
    private(set) var saved: SavedState?

    init(_ state: SavedState? = nil) {
        saved = state
    }

    func load() -> SavedState? { saved }
    func save(_ state: SavedState) { saved = state }
}
