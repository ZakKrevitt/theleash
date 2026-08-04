import AppKit
import Combine
import LeashCore

@MainActor
final class LeashCoordinator: NSObject, ObservableObject {
    @Published private(set) var state: LeashState
    @Published private(set) var runningApps: [AppIdentity] = []
    @Published private(set) var now = Date()
    @Published private(set) var timeboxEnded = false
    @Published var selectedBundleIdentifiers: Set<String> = []
    @Published var selectedAnchorBundleIdentifier: String?
    @Published var taskDraft = ""
    @Published var doneWhenDraft = ""
    @Published var durationMinutes = 25
    @Published var mode: LeashMode = .nudge
    @Published var formError: String?
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var releaseHotKeyDisplayName: String?

    private let store = StateStore()
    private let overlay = OverlayController()
    private let workspace = NSWorkspace.shared
    private var clock: Timer?
    private var isPullingBack = false
    private var releaseHotKey: ReleaseHotKey?
    private var firstLaunchWindow: FirstLaunchWindowController?

    private var leashBundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "com.zakkrevitt.leash"
    }

    override init() {
        state = store.load()
        hasCompletedOnboarding = store.hasCompletedOnboarding
        releaseHotKeyDisplayName = nil
        super.init()

        let center = workspace.notificationCenter
        center.addObserver(
            self,
            selector: #selector(applicationActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(applicationsChanged(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(applicationTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        refreshRunningApps()
        restoreSessionIfNeeded()
        releaseHotKey = ReleaseHotKey.register { [weak self] in
            self?.releaseSession()
        }
        releaseHotKeyDisplayName = releaseHotKey?.displayName
        if !hasCompletedOnboarding {
            firstLaunchWindow = FirstLaunchWindowController(coordinator: self)
            firstLaunchWindow?.present()
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        clock?.invalidate()
    }

    var session: FocusSession? { state.session }
    var parked: [ParkedApp] { state.parked }
    var selectedAnchor: AppIdentity? {
        runningApps.first { $0.bundleIdentifier == selectedAnchorBundleIdentifier }
    }

    var canCompleteSession: Bool {
        session.map(SessionEngine.canComplete) ?? false
    }

    var remainingText: String {
        guard let session else { return "0:00" }
        return SessionEngine.remainingText(for: session, now: now)
    }

    var selectedAnchorIsBrowser: Bool {
        selectedAnchor?.isWebBrowser == true
    }

    var currentAppToAllow: AppIdentity? {
        guard let session,
              let running = workspace.frontmostApplication,
              let app = identity(for: running),
              app.bundleIdentifier != leashBundleIdentifier,
              !session.allowedBundleIdentifiers.contains(app.bundleIdentifier) else { return nil }
        return app
    }

    func finishOnboarding() {
        store.completeOnboarding()
        hasCompletedOnboarding = true
        firstLaunchWindow?.showSetup()
    }

    func toggleAllowed(_ app: AppIdentity) {
        if selectedBundleIdentifiers.contains(app.bundleIdentifier) {
            selectedBundleIdentifiers.remove(app.bundleIdentifier)
        } else {
            selectedBundleIdentifiers.insert(app.bundleIdentifier)
        }
    }

    func isSelected(_ app: AppIdentity) -> Bool {
        selectedBundleIdentifiers.contains(app.bundleIdentifier) ||
            app.bundleIdentifier == selectedAnchorBundleIdentifier
    }

    func icon(for app: AppIdentity) -> NSImage {
        let running = workspace.runningApplications.first { $0.bundleIdentifier == app.bundleIdentifier }
        return running?.icon ?? NSWorkspace.shared.icon(for: .application)
    }

    func startSession(finishLineItems: [String]? = nil) {
        formError = nil
        do {
            if finishLineItems == nil,
               doneWhenDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formError = "Write a finish line that can be answered with yes or no."
                return
            }
            let nextSession = try SessionEngine.start(
                task: taskDraft,
                doneWhen: doneWhenDraft,
                durationMinutes: durationMinutes,
                mode: mode,
                anchor: selectedAnchor,
                allowedBundleIdentifiers: selectedBundleIdentifiers,
                finishLineItems: finishLineItems,
                now: Date()
            )
            state.session = nextSession
            state.lastStopReason = nil
            save()
            timeboxEnded = false
            startClock()
            overlay.start(
                task: nextSession.task,
                remaining: SessionEngine.remainingText(for: nextSession)
            )
            firstLaunchWindow?.close()
            firstLaunchWindow = nil
        } catch {
            formError = error.localizedDescription
        }
    }

    func endSession(reason: String = "stopped") {
        SessionEngine.release(state: &state, reason: reason)
        save()
        overlay.stop()
        stopClock()
        timeboxEnded = false
        isPullingBack = false
        validateSelectedAnchor()
    }

    func releaseSession() {
        guard state.session != nil else { return }
        endSession(reason: "emergency-release")
    }

    func quitApplication() {
        if state.session != nil {
            endSession(reason: "quit")
        } else {
            overlay.stop()
        }
        NSApplication.shared.terminate(nil)
    }

    func completeSession() {
        guard let session = state.session,
              SessionEngine.canComplete(session) else { return }
        SessionEngine.complete(state: &state)
        save()
        stopClock()
        timeboxEnded = false
        isPullingBack = false
        taskDraft = ""
        doneWhenDraft = ""
        selectedBundleIdentifiers.removeAll()
        selectedAnchorBundleIdentifier = nil
        overlay.showCompletion(task: session.task)
    }

    func toggleFinishLineItem(_ item: FinishLineItem) {
        SessionEngine.toggleFinishLineItem(id: item.id, state: &state)
        save()
        if timeboxEnded, let session {
            overlay.updateTimeboxEnded(
                finishLine: finishLineStatus(for: session),
                canComplete: SessionEngine.canComplete(session)
            )
        }
    }

    func extendTimebox(minutes: Int = 10) {
        guard var session = state.session else { return }
        SessionEngine.extend(session: &session, minutes: minutes)
        state.session = session
        save()
        timeboxEnded = false
        startClock()
        overlay.start(task: session.task, remaining: SessionEngine.remainingText(for: session))
    }

    func returnToTask() {
        guard let anchor = state.session?.anchor else { return }
        if !activate(anchor) { endSession(reason: "anchor-closed") }
    }

    func allowCurrentApp() {
        guard var session = state.session,
              let app = currentAppToAllow else { return }
        if !session.allowedBundleIdentifiers.contains(app.bundleIdentifier),
           session.allowedBundleIdentifiers.count >= InputLimits.allowedAppCount {
            return
        }
        session.allowedBundleIdentifiers.insert(app.bundleIdentifier)
        state.session = session
        save()
    }

    func openParked(_ item: ParkedApp) {
        guard activate(item.app) else { return }
        removeParked(item)
    }

    func canOpenParked(_ item: ParkedApp) -> Bool {
        runningApplication(for: item.app) != nil
    }

    func removeParked(_ item: ParkedApp) {
        state.parked.removeAll { $0.id == item.id }
        save()
    }

    func clearParked() {
        state.parked.removeAll()
        save()
    }

    @objc private func applicationActivated(_ notification: Notification) {
        refreshRunningApps()
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let app = identity(for: application),
              app.bundleIdentifier != leashBundleIdentifier else { return }

        guard let session = state.session else { return }
        guard !timeboxEnded else { return }

        let decision = SessionEngine.decision(
            for: app,
            session: session,
            leashBundleIdentifier: leashBundleIdentifier
        )
        if !SessionEngine.shouldShowCompanion(for: decision) {
            if !isPullingBack { overlay.hide() }
            return
        }
        guard !isPullingBack else { return }

        SessionEngine.park(
            app: app,
            state: &state
        )
        save()
        overlay.showCatch(
            appName: app.name,
            task: session.task,
            finishLine: finishLineStatus(for: session),
            canComplete: SessionEngine.canComplete(session),
            pulledBack: decision == .pullBack,
            onComplete: { [weak self] in self?.completeSession() },
            onReturn: { [weak self] in
                self?.overlay.hide()
                self?.returnToTask()
            }
        )

        guard decision == .pullBack else { return }
        isPullingBack = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            guard self.state.session?.id == session.id else {
                self.isPullingBack = false
                return
            }
            guard self.activate(session.anchor) else {
                self.endSession(reason: "anchor-closed")
                return
            }
            application.hide()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.isPullingBack = false
            }
        }
    }

    @objc private func applicationsChanged(_ notification: Notification) {
        refreshRunningApps()
    }

    @objc private func applicationTerminated(_ notification: Notification) {
        refreshRunningApps()
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let app = identity(for: application) else { return }
        if let session = state.session,
           SessionEngine.shouldRelease(session: session, terminatedApp: app) {
            endSession(reason: "anchor-closed")
        }
    }

    private func startClock() {
        guard clock == nil else { return }
        now = Date()
        clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let clock { RunLoop.main.add(clock, forMode: .common) }
    }

    private func stopClock() {
        clock?.invalidate()
        clock = nil
    }

    private func tick() {
        guard let session = state.session else {
            stopClock()
            return
        }
        now = Date()
        if SessionEngine.isExpired(session, now: now) {
            stopClock()
            timeboxEnded = true
            overlay.showTimeboxEnded(
                task: session.task,
                finishLine: finishLineStatus(for: session),
                canComplete: SessionEngine.canComplete(session),
                onComplete: { [weak self] in self?.completeSession() },
                onExtend: { [weak self] in self?.extendTimebox() },
                onRelease: { [weak self] in self?.endSession(reason: "time-ended") }
            )
            return
        }
        overlay.update(task: session.task, remaining: remainingText)
    }

    private func restoreSessionIfNeeded() {
        guard let session = state.session else { return }
        if runningApplication(for: session.anchor) == nil {
            endSession(reason: "anchor-closed")
        } else if SessionEngine.isExpired(session) {
            endSession(reason: "time-ended")
        } else {
            overlay.start(task: session.task, remaining: SessionEngine.remainingText(for: session))
            startClock()
        }
    }

    private func validateSelectedAnchor() {
        if let selectedAnchorBundleIdentifier,
           runningApps.contains(where: { $0.bundleIdentifier == selectedAnchorBundleIdentifier }) {
            return
        }
        selectedAnchorBundleIdentifier = nil
    }

    private func refreshRunningApps() {
        runningApps = workspace.runningApplications
            .filter { !$0.isTerminated && $0.activationPolicy == .regular }
            .compactMap(identity(for:))
            .filter { $0.bundleIdentifier != leashBundleIdentifier }
            .reduce(into: [String: AppIdentity]()) { result, app in
                result[app.bundleIdentifier] = app
            }
            .values
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        validateSelectedAnchor()
    }

    private func finishLineStatus(for session: FocusSession) -> String? {
        if let items = session.finishLineItems, !items.isEmpty {
            let completed = items.filter(\.isComplete).count
            return "\(completed) of \(items.count) finish-line steps complete"
        }
        return session.doneWhen.isEmpty ? nil : "Done means: \(session.doneWhen)"
    }

    private func identity(for application: NSRunningApplication) -> AppIdentity? {
        guard let bundleIdentifier = application.bundleIdentifier,
              let name = application.localizedName else { return nil }
        let identity = AppIdentity(bundleIdentifier: bundleIdentifier, name: name)
        guard !identity.bundleIdentifier.isEmpty, !identity.name.isEmpty else { return nil }
        return identity
    }

    private func runningApplication(for app: AppIdentity) -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleIdentifier)
            .first { !$0.isTerminated }
    }

    @discardableResult
    private func activate(_ app: AppIdentity) -> Bool {
        guard let application = runningApplication(for: app) else { return false }
        application.activate(options: [.activateAllWindows])
        return true
    }

    private func save() {
        store.save(state)
    }
}
