import Foundation
import LeashCore

struct StateStore {
    private let key = "leash.state.v1"
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> LeashState {
        guard let data = defaults.data(forKey: key),
              let state = try? decoder.decode(LeashState.self, from: data) else {
            return LeashState()
        }
        return state
    }

    func save(_ state: LeashState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}
