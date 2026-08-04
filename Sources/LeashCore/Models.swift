import Foundation

public struct AppIdentity: Codable, Hashable, Identifiable, Sendable {
    public let bundleIdentifier: String
    public let name: String

    public var id: String { bundleIdentifier }

    public init(bundleIdentifier: String, name: String) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
    }
}

public enum LeashMode: String, Codable, CaseIterable, Sendable {
    case nudge
    case lock

    public var title: String {
        switch self {
        case .nudge: "Catch me"
        case .lock: "Pull me back"
        }
    }

    public var detail: String {
        switch self {
        case .nudge: "Show the leash when I wander"
        case .lock: "Hide the distraction and restore my task"
        }
    }
}

public struct FinishLineItem: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let text: String
    public var isComplete: Bool

    public init(id: UUID = UUID(), text: String, isComplete: Bool = false) {
        self.id = id
        self.text = text
        self.isComplete = isComplete
    }
}

public struct FocusSession: Codable, Equatable, Sendable {
    public let id: UUID
    public let task: String
    public let doneWhen: String
    public let mode: LeashMode
    public let startedAt: Date
    public var endsAt: Date
    public let anchor: AppIdentity
    public var allowedBundleIdentifiers: Set<String>
    public var catchCount: Int
    public var finishLineItems: [FinishLineItem]?

    public init(
        id: UUID = UUID(),
        task: String,
        doneWhen: String,
        mode: LeashMode,
        startedAt: Date,
        endsAt: Date,
        anchor: AppIdentity,
        allowedBundleIdentifiers: Set<String>,
        catchCount: Int = 0,
        finishLineItems: [FinishLineItem]? = nil
    ) {
        self.id = id
        self.task = task
        self.doneWhen = doneWhen
        self.mode = mode
        self.startedAt = startedAt
        self.endsAt = endsAt
        self.anchor = anchor
        self.allowedBundleIdentifiers = allowedBundleIdentifiers
        self.catchCount = catchCount
        self.finishLineItems = finishLineItems
    }
}

public struct ParkedApp: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let app: AppIdentity
    public let windowTitle: String?
    public let parkedAt: Date

    public init(
        id: UUID = UUID(),
        app: AppIdentity,
        windowTitle: String? = nil,
        parkedAt: Date = Date()
    ) {
        self.id = id
        self.app = app
        self.windowTitle = windowTitle
        self.parkedAt = parkedAt
    }
}

public struct LeashState: Codable, Equatable, Sendable {
    public var session: FocusSession?
    public var parked: [ParkedApp]
    public var lastStopReason: String?

    public init(
        session: FocusSession? = nil,
        parked: [ParkedApp] = [],
        lastStopReason: String? = nil
    ) {
        self.session = session
        self.parked = parked
        self.lastStopReason = lastStopReason
    }
}
