import Foundation

public enum SessionError: LocalizedError, Equatable {
    case missingTask
    case missingFinishLine
    case missingAnchor
    case invalidDuration

    public var errorDescription: String? {
        switch self {
        case .missingTask: "Name the task before starting."
        case .missingFinishLine: "Add at least one finish-line step."
        case .missingAnchor: "Choose the main app for this leash."
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
        finishLineItems: [String]? = nil,
        now: Date = Date()
    ) throws -> FocusSession {
        let cleanTask = InputLimits.text(task, maximumLength: InputLimits.taskLength)
        guard !cleanTask.isEmpty else { throw SessionError.missingTask }
        guard let anchor, !anchor.bundleIdentifier.isEmpty else { throw SessionError.missingAnchor }
        guard (1...180).contains(durationMinutes) else { throw SessionError.invalidDuration }

        let allowed = normalizedAllowedApps(allowedBundleIdentifiers, anchor: anchor)

        let items: [FinishLineItem]?
        if let finishLineItems {
            let cleaned = finishLineItems
                .map { InputLimits.text($0, maximumLength: InputLimits.finishLineItemLength) }
                .filter { !$0.isEmpty }
                .prefix(InputLimits.finishLineItemCount)
                .map { FinishLineItem(text: $0) }
            guard !cleaned.isEmpty else { throw SessionError.missingFinishLine }
            items = Array(cleaned)
        } else {
            items = nil
        }

        return FocusSession(
            task: cleanTask,
            doneWhen: InputLimits.text(doneWhen, maximumLength: InputLimits.doneWhenLength),
            mode: mode,
            startedAt: now,
            endsAt: now.addingTimeInterval(TimeInterval(durationMinutes * 60)),
            anchor: anchor,
            allowedBundleIdentifiers: allowed,
            finishLineItems: items
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

    public static func canComplete(_ session: FocusSession) -> Bool {
        guard let items = session.finishLineItems, !items.isEmpty else { return true }
        return items.allSatisfy(\.isComplete)
    }

    public static func toggleFinishLineItem(id: UUID, state: inout LeashState) {
        guard var session = state.session,
              let index = session.finishLineItems?.firstIndex(where: { $0.id == id }) else { return }
        session.finishLineItems?[index].isComplete.toggle()
        state.session = session
    }

    public static func extend(session: inout FocusSession, minutes: Int, now: Date = Date()) {
        guard minutes > 0 else { return }
        session.endsAt = now.addingTimeInterval(TimeInterval(minutes * 60))
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
        state: inout LeashState,
        now: Date = Date()
    ) {
        guard var session = state.session else { return }
        session.catchCount = session.catchCount < 1_000_000
            ? max(0, session.catchCount + 1)
            : 1_000_000
        state.session = session

        let item = ParkedApp(app: app, parkedAt: now)
        state.parked.removeAll { $0.app.bundleIdentifier == item.app.bundleIdentifier }
        state.parked.insert(item, at: 0)
        state.parked = Array(state.parked.prefix(InputLimits.parkedItemCount))
    }

    public static func persistentState(from state: LeashState) -> LeashState {
        normalizedState(state)
    }

    public static func restoredState(from state: LeashState, now: Date = Date()) -> LeashState {
        var result = persistentState(from: state)
        guard let session = result.session else { return result }

        let duration = session.endsAt.timeIntervalSince(session.startedAt)
        let startsUnreasonablyFarInFuture = session.startedAt > now.addingTimeInterval(5 * 60)
        guard !session.task.isEmpty,
              !session.anchor.bundleIdentifier.isEmpty,
              duration > 0,
              duration <= InputLimits.maximumSessionDuration,
              !startsUnreasonablyFarInFuture else {
            result.session = nil
            result.lastStopReason = "invalid-state"
            return result
        }
        return result
    }

    private static func normalizedState(_ state: LeashState) -> LeashState {
        let knownStopReasons = [
            "complete", "stopped", "emergency-release", "quit",
            "anchor-closed", "time-ended", "invalid-state",
        ]
        let parked = state.parked.prefix(InputLimits.parkedItemCount).map { item in
            ParkedApp(
                id: item.id,
                app: AppIdentity(
                    bundleIdentifier: item.app.bundleIdentifier,
                    name: item.app.name
                ),
                parkedAt: item.parkedAt
            )
        }

        let session = state.session.map { session in
            let anchor = AppIdentity(
                bundleIdentifier: session.anchor.bundleIdentifier,
                name: session.anchor.name
            )
            let allowed = normalizedAllowedApps(
                session.allowedBundleIdentifiers,
                anchor: anchor
            )
            let finishLineItems = session.finishLineItems.map { items in
                items.prefix(InputLimits.finishLineItemCount).compactMap { item in
                    let text = InputLimits.text(
                        item.text,
                        maximumLength: InputLimits.finishLineItemLength
                    )
                    return text.isEmpty ? nil : FinishLineItem(
                        id: item.id,
                        text: text,
                        isComplete: item.isComplete
                    )
                }
            }
            return FocusSession(
                id: session.id,
                task: InputLimits.text(session.task, maximumLength: InputLimits.taskLength),
                doneWhen: InputLimits.text(session.doneWhen, maximumLength: InputLimits.doneWhenLength),
                mode: session.mode,
                startedAt: session.startedAt,
                endsAt: session.endsAt,
                anchor: anchor,
                allowedBundleIdentifiers: allowed,
                catchCount: max(0, min(session.catchCount, 1_000_000)),
                finishLineItems: finishLineItems
            )
        }

        return LeashState(
            session: session,
            parked: parked,
            lastStopReason: state.lastStopReason.flatMap {
                knownStopReasons.contains($0) ? $0 : nil
            }
        )
    }

    private static func normalizedAllowedApps(
        _ bundleIdentifiers: Set<String>,
        anchor: AppIdentity
    ) -> Set<String> {
        var allowed = Set(
            bundleIdentifiers
                .map { InputLimits.text($0, maximumLength: InputLimits.bundleIdentifierLength) }
                .filter { !$0.isEmpty && $0 != anchor.bundleIdentifier }
                .prefix(InputLimits.allowedAppCount - 1)
        )
        if !anchor.bundleIdentifier.isEmpty { allowed.insert(anchor.bundleIdentifier) }
        return allowed
    }
}
