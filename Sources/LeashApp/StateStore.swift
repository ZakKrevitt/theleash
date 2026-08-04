import Foundation
import LeashCore

struct StateStore {
    private let key = "leash.state.v1"
    private let onboardingKey = "leash.onboarding.completed.v1"
    private let maximumStateSize = 256 * 1_024
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> LeashState {
        guard let data = defaults.data(forKey: key) else {
            return LeashState()
        }
        guard data.count <= maximumStateSize,
              let state = try? decoder.decode(LeashState.self, from: data) else {
            defaults.removeObject(forKey: key)
            return LeashState()
        }

        let restored = SessionEngine.restoredState(from: state)
        if let normalizedData = try? encoder.encode(restored),
           normalizedData != data {
            defaults.set(normalizedData, forKey: key)
        }
        return restored
    }

    func save(_ state: LeashState) {
        let persistentState = SessionEngine.persistentState(from: state)
        guard let data = try? encoder.encode(persistentState),
              data.count <= maximumStateSize else { return }
        defaults.set(data, forKey: key)
    }

    var hasCompletedOnboarding: Bool {
        defaults.bool(forKey: onboardingKey)
    }

    func completeOnboarding() {
        defaults.set(true, forKey: onboardingKey)
    }
}
