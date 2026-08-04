import XCTest
@testable import LeashCore

final class SessionEngineTests: XCTestCase {
    private let anchor = AppIdentity(bundleIdentifier: "com.apple.TextEdit", name: "TextEdit")
    private let browser = AppIdentity(bundleIdentifier: "com.google.Chrome", name: "Google Chrome")

    func testBrowserIdentityRecognizesReleaseChannelsWithoutFlaggingOtherApps() {
        XCTAssertTrue(browser.isWebBrowser)
        XCTAssertTrue(AppIdentity(
            bundleIdentifier: "org.mozilla.firefoxdeveloperedition",
            name: "Firefox Developer Edition"
        ).isWebBrowser)
        XCTAssertFalse(anchor.isWebBrowser)
    }

    func testStartCreatesTaskContractAndIncludesAnchor() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let session = try SessionEngine.start(
            task: "  Write the project brief  ",
            doneWhen: " Draft sent ",
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor,
            allowedBundleIdentifiers: [browser.bundleIdentifier],
            now: now
        )

        XCTAssertEqual(session.task, "Write the project brief")
        XCTAssertEqual(session.doneWhen, "Draft sent")
        XCTAssertEqual(session.endsAt, now.addingTimeInterval(1_500))
        XCTAssertEqual(session.allowedBundleIdentifiers, [anchor.bundleIdentifier, browser.bundleIdentifier])
    }

    func testStartRejectsMissingInputsAndBadDuration() {
        XCTAssertThrowsError(try SessionEngine.start(
            task: " ", durationMinutes: 25, mode: .nudge, anchor: anchor
        )) { XCTAssertEqual($0 as? SessionError, .missingTask) }

        XCTAssertThrowsError(try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: nil
        )) { XCTAssertEqual($0 as? SessionError, .missingAnchor) }

        XCTAssertThrowsError(try SessionEngine.start(
            task: "Work", durationMinutes: 181, mode: .nudge, anchor: anchor
        )) { XCTAssertEqual($0 as? SessionError, .invalidDuration) }

        XCTAssertThrowsError(try SessionEngine.start(
            task: "Work",
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor,
            finishLineItems: [" "]
        )) { XCTAssertEqual($0 as? SessionError, .missingFinishLine) }
    }

    func testChecklistGatesCompletionUntilEveryStepIsChecked() throws {
        let session = try SessionEngine.start(
            task: "Ship the brief",
            durationMinutes: 25,
            mode: .nudge,
            anchor: browser,
            allowedBundleIdentifiers: [anchor.bundleIdentifier],
            finishLineItems: [" Draft written ", "Sent to Maya"]
        )
        var state = LeashState(session: session)

        XCTAssertEqual(session.anchor, browser)
        XCTAssertEqual(session.finishLineItems?.map(\.text), ["Draft written", "Sent to Maya"])
        XCTAssertFalse(SessionEngine.canComplete(session))

        for item in try XCTUnwrap(session.finishLineItems) {
            SessionEngine.toggleFinishLineItem(id: item.id, state: &state)
        }

        XCTAssertTrue(try SessionEngine.canComplete(XCTUnwrap(state.session)))
    }

    func testChecklistSurvivesPersistentStateNormalization() throws {
        let session = try SessionEngine.start(
            task: "Ship the brief",
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor,
            finishLineItems: ["Draft written", "Sent to Maya"]
        )
        var state = LeashState(session: session)
        let firstItem = try XCTUnwrap(session.finishLineItems?.first)
        SessionEngine.toggleFinishLineItem(id: firstItem.id, state: &state)

        let persistent = SessionEngine.persistentState(from: state)

        XCTAssertEqual(persistent.session?.finishLineItems?.map(\.text), ["Draft written", "Sent to Maya"])
        XCTAssertEqual(persistent.session?.finishLineItems?.map(\.isComplete), [true, false])
    }

    func testExtendingExpiredSessionStartsANewTimeboxFromNow() throws {
        let now = Date(timeIntervalSince1970: 2_000)
        var session = try SessionEngine.start(
            task: "Work", durationMinutes: 1, mode: .nudge, anchor: anchor, now: now
        )

        SessionEngine.extend(session: &session, minutes: 10, now: now.addingTimeInterval(90))

        XCTAssertEqual(session.endsAt, now.addingTimeInterval(690))
    }

    func testDriftDecisionRespectsModeAndAllowlist() throws {
        let allowed = try SessionEngine.start(
            task: "Work",
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor,
            allowedBundleIdentifiers: [browser.bundleIdentifier]
        )
        XCTAssertEqual(
            SessionEngine.decision(for: browser, session: allowed, leashBundleIdentifier: "app.leash"),
            .allow
        )

        let distraction = AppIdentity(bundleIdentifier: "com.spotify.client", name: "Spotify")
        XCTAssertEqual(
            SessionEngine.decision(for: distraction, session: allowed, leashBundleIdentifier: "app.leash"),
            .nudge
        )

        let locked = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .lock, anchor: anchor
        )
        XCTAssertEqual(
            SessionEngine.decision(for: distraction, session: locked, leashBundleIdentifier: "app.leash"),
            .pullBack
        )
    }

    func testCompanionOnlyAppearsForAnIntervention() {
        XCTAssertFalse(SessionEngine.shouldShowCompanion(for: .allow))
        XCTAssertTrue(SessionEngine.shouldShowCompanion(for: .nudge))
        XCTAssertTrue(SessionEngine.shouldShowCompanion(for: .pullBack))
    }

    func testParkingDeduplicatesAndCountsEveryCatch() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )
        var state = LeashState(session: session)
        let distraction = AppIdentity(bundleIdentifier: "com.spotify.client", name: "Spotify")

        SessionEngine.park(app: distraction, state: &state)
        SessionEngine.park(app: distraction, state: &state)

        XCTAssertEqual(state.session?.catchCount, 2)
        XCTAssertEqual(state.parked.count, 1)
    }

    func testRemainingTimeRoundsUpAndExpiresAtBoundary() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 1, mode: .nudge, anchor: anchor, now: now
        )

        XCTAssertEqual(SessionEngine.remainingText(for: session, now: now.addingTimeInterval(0.2)), "1:00")
        XCTAssertTrue(SessionEngine.isExpired(session, now: now.addingTimeInterval(60)))
    }

    func testCompleteEndsSessionAndRecordsSuccessfulOutcome() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )
        var state = LeashState(session: session)

        SessionEngine.complete(state: &state)

        XCTAssertNil(state.session)
        XCTAssertEqual(state.lastStopReason, "complete")
    }

    func testReleaseEndsSessionAndRecordsReason() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )
        var state = LeashState(session: session)

        SessionEngine.release(state: &state, reason: "emergency-release")

        XCTAssertNil(state.session)
        XCTAssertEqual(state.lastStopReason, "emergency-release")
    }

    func testAnchorTerminationOnlyReleasesMatchingSession() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )

        XCTAssertTrue(SessionEngine.shouldRelease(session: session, terminatedApp: anchor))
        XCTAssertFalse(SessionEngine.shouldRelease(session: session, terminatedApp: browser))
    }

    func testStartBoundsUserControlledText() throws {
        let session = try SessionEngine.start(
            task: String(repeating: "a", count: InputLimits.taskLength + 20),
            doneWhen: String(repeating: "b", count: InputLimits.doneWhenLength + 20),
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor
        )

        XCTAssertEqual(session.task.count, InputLimits.taskLength)
        XCTAssertEqual(session.doneWhen.count, InputLimits.doneWhenLength)
    }

    func testStartBoundsAllowedAppsAndAlwaysIncludesAnchor() throws {
        let allowed = Set((0..<200).map { "app.\($0)" })

        let session = try SessionEngine.start(
            task: "Work",
            durationMinutes: 25,
            mode: .nudge,
            anchor: anchor,
            allowedBundleIdentifiers: allowed
        )

        XCTAssertLessThanOrEqual(session.allowedBundleIdentifiers.count, InputLimits.allowedAppCount)
        XCTAssertTrue(session.allowedBundleIdentifiers.contains(anchor.bundleIdentifier))
    }

    func testParkedStateJSONContainsNoWindowOrDocumentContent() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )
        var state = LeashState(session: session)

        SessionEngine.park(app: browser, state: &state)
        let data = try JSONEncoder().encode(state.parked[0])
        let json = try XCTUnwrap(String(data: data, encoding: .utf8))

        XCTAssertFalse(json.localizedCaseInsensitiveContains("window"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("document"))
        XCTAssertFalse(json.localizedCaseInsensitiveContains("content"))
    }

    func testEndingSessionKeepsOnlyAppLevelHistory() throws {
        let session = try SessionEngine.start(
            task: "Work", durationMinutes: 25, mode: .nudge, anchor: anchor
        )
        let parked = ParkedApp(app: browser)
        var completedState = LeashState(session: session, parked: [parked])
        var releasedState = LeashState(session: session, parked: [parked])

        SessionEngine.complete(state: &completedState)
        SessionEngine.release(state: &releasedState, reason: "stopped")

        XCTAssertEqual(completedState.parked.first?.app, browser)
        XCTAssertEqual(releasedState.parked.first?.app, browser)
    }

    func testPersistentStateBoundsHistory() {
        let parked = (0..<75).map { index in
            ParkedApp(app: AppIdentity(bundleIdentifier: "app.\(index)", name: "App \(index)"))
        }

        let persistent = SessionEngine.persistentState(from: LeashState(parked: parked))

        XCTAssertEqual(persistent.parked.count, InputLimits.parkedItemCount)
    }

    func testRestoreRejectsStructurallyInvalidSession() {
        let now = Date(timeIntervalSince1970: 10_000)
        let invalid = FocusSession(
            task: "Work",
            doneWhen: "",
            mode: .lock,
            startedAt: now,
            endsAt: now.addingTimeInterval(4 * 60 * 60),
            anchor: anchor,
            allowedBundleIdentifiers: [anchor.bundleIdentifier]
        )

        let restored = SessionEngine.restoredState(from: LeashState(session: invalid), now: now)

        XCTAssertNil(restored.session)
        XCTAssertEqual(restored.lastStopReason, "invalid-state")
    }

    func testRestoreBoundsAllowedAppsAndCatchCount() {
        let now = Date(timeIntervalSince1970: 10_000)
        let allowed = Set((0..<200).map { "app.\($0)" })
        let session = FocusSession(
            task: "Work",
            doneWhen: "",
            mode: .lock,
            startedAt: now,
            endsAt: now.addingTimeInterval(60),
            anchor: anchor,
            allowedBundleIdentifiers: allowed,
            catchCount: Int.max
        )

        let restored = SessionEngine.restoredState(from: LeashState(session: session), now: now)

        XCTAssertLessThanOrEqual(
            restored.session?.allowedBundleIdentifiers.count ?? 0,
            InputLimits.allowedAppCount
        )
        XCTAssertEqual(restored.session?.catchCount, 1_000_000)
        XCTAssertTrue(restored.session?.allowedBundleIdentifiers.contains(anchor.bundleIdentifier) == true)
    }
}
