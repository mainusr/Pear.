import Foundation
import Observation

/// One pinned source per show. A source is identified by add-on + its display name
/// (e.g. "PenguPlay 1080p"), because stream URLs change per episode.
struct Pin: Codable { let addonID: String; let signature: String }

@MainActor @Observable
final class PinnedSources {
    private var pins: [String: Pin] = [:]
    /// The source last picked by hand for each show / movie. Unlike a pin it is remembered automatically.
    private var last: [String: Pin] = [:]
    private let key = "pinned.sources"
    private let lastKey = "last.sources"

    init() { reload() }
    func reload() {
        pins = UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode([String: Pin].self, from: $0) } ?? [:]
        last = UserDefaults.standard.data(forKey: lastKey).flatMap { try? JSONDecoder().decode([String: Pin].self, from: $0) } ?? [:]
    }
    func lastChosen(for show: String) -> Pin? { last[show] }
    /// Called whenever the user picks a source, so the next episode or resume tries the same one.
    func remember(_ p: Pin, for show: String) {
        guard last[show]?.addonID != p.addonID || last[show]?.signature != p.signature else { return }
        last[show] = p
        UserDefaults.standard.set(try? JSONEncoder().encode(last), forKey: lastKey)
    }
    /// What to try first: the last source picked, then the pin.
    func preferred(for show: String) -> Pin? { last[show] ?? pins[show] }
    func pin(for show: String) -> Pin? { pins[show] }
    func set(_ p: Pin, for show: String) { pins[show] = p; save() }
    func remove(for show: String) { pins[show] = nil; save() }
    private func save() { UserDefaults.standard.set(try? JSONEncoder().encode(pins), forKey: key) }
}

extension StreamItem {
    var signature: String { (name ?? title ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }
}
