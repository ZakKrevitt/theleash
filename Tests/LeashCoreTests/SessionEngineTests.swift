import XCTest
@testable import LeashCore

final class SessionEngineTests: XCTestCase {
    private let anchor = AppIdentity(bundleIdentifier: "com.apple.TextEdit", name: "TextEdit")
    private let browser = AppIdentity(bundleIdentifier: "com.google.Chrome", name: "Google Chrome")

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

        SessionEngine.park(app: distraction, windowTitle: "Playlist", state: &state)
        SessionEngine.park(app: distraction, windowTitle: "Playlist", state: &state)

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
}
