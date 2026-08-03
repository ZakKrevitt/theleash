import Foundation

public enum SessionError: LocalizedError, Equatable {
    case missingTask
    case missingAnchor
    case invalidDuration

    public var errorDescription: String? {
        switch self {
        case .missingTask: "Name the task before starting."
        case .missingAnchor: "Open the app where the work should happen, then start the leash."
        case .invalidDuration: "Choose a session between 1 and 180 minutes."
        }
    }
}

public enum DriftDecision: Equatable, Sendable {
    case allow
    case nudge
    case pullBack
}

public enum SessionEngine {
    public static func start(
        task: String,
        doneWhen: String = "",
        durationMinutes: Int,
        mode: LeashMode,
        anchor: AppIdentity?,
        allowedBundleIdentifiers: Set<String> = [],
        now: Date = Date()
    ) throws -> FocusSession {
        let cleanTask = task.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTask.isEmpty else { throw SessionError.missingTask }
        guard let anchor else { throw SessionError.missingAnchor }
        guard (1...180).contains(durationMinutes) else { throw SessionError.invalidDuration }

        var allowed = allowedBundleIdentifiers
        allowed.insert(anchor.bundleIdentifier)

        return FocusSession(
            task: cleanTask,
            doneWhen: doneWhen.trimmingCharacters(in: .whitespacesAndNewlines),
            mode: mode,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            anchor: anchor,
            allowedBundleIdentifiers: allowed
        )
    }

    public static func decision(
        for app: AppIdentity,
        session: FocusSession,
        leashBundleIdentifier: String
    ) -> DriftDecision {
        if app.bundleIdentifier == leashBundleIdentifier ||
            session.allowedBundleIdentifiers.contains(app.bundleIdentifier) {
            return .allow
        }
        return session.mode == .lock ? .pullBack : .nudge
    }

    public static func shouldShowCompanion(for decision: DriftDecision) -> Bool {
        decision != .allow
    }

    public static func remainingText(for session: FocusSession, now: Date = Date()) -> String {
        let totalSeconds = max(0, Int(ceil(session.endsAt.timeIntervalSince(now))))
        return String(format: "%d:%02d", totalSeconds / 60, totalSeconds % 60)
    }

    public static func isExpired(_ session: FocusSession, now: Date = Date()) -> Bool {
        session.endsAt <= now
    }

    public static func complete(state: inout LeashState) {
        state.session = nil
        state.lastStopReason = "complete"
    }

    public static func release(state: inout LeashState, reason: String) {
        state.session = nil
        state.lastStopReason = reason
    }

    public static func shouldRelease(session: FocusSession, terminatedApp: AppIdentity) -> Bool {
        session.anchor.bundleIdentifier == terminatedApp.bundleIdentifier
    }

    public static func park(
        app: AppIdentity,
        windowTitle: String?,
        state: inout LeashState,
        now: Date = Date()
    ) {
        guard var session = state.session else { return }
        session.catchCount += 1
        state.session = session

        let item = ParkedApp(app: app, windowTitle: windowTitle, parkedAt: now)
        state.parked.removeAll { $0.app.bundleIdentifier == app.bundleIdentifier && $0.windowTitle == windowTitle }
        state.parked.insert(item, at: 0)
        state.parked = Array(state.parked.prefix(50))
    }
}
