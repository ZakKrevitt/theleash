import Foundation

public enum InputLimits {
    public static let taskLength = 240
    public static let doneWhenLength = 480
    public static let appNameLength = 160
    public static let bundleIdentifierLength = 255
    public static let allowedAppCount = 128
    public static let parkedItemCount = 50
    public static let finishLineItemCount = 12
    public static let finishLineItemLength = 240
    public static let maximumSessionDuration: TimeInterval = 3 * 60 * 60

    public static func text(_ value: String, maximumLength: Int, trimmingWhitespace: Bool = true) -> String {
        let bounded = String(value.prefix(maximumLength))
        return trimmingWhitespace
            ? bounded.trimmingCharacters(in: .whitespacesAndNewlines)
            : bounded
    }
}

public struct AppIdentity: Codable, Hashable, Identifiable, Sendable {
    public let bundleIdentifier: String
    public let name: String

    public var id: String { bundleIdentifier }

    public var isWebBrowser: Bool {
        let browserBundleIdentifiers = [
            "com.apple.Safari",
            "com.brave.Browser",
            "com.google.Chrome",
            "com.microsoft.edgemac",
            "com.operasoftware.Opera",
            "com.vivaldi.Vivaldi",
            "company.thebrowser.Browser",
            "org.mozilla.firefox",
            "org.mozilla.firefoxdeveloperedition",
        ]
        return browserBundleIdentifiers.contains {
            bundleIdentifier == $0 || bundleIdentifier.hasPrefix("\($0).")
        }
    }

    public init(bundleIdentifier: String, name: String) {
        self.bundleIdentifier = InputLimits.text(
            bundleIdentifier,
            maximumLength: InputLimits.bundleIdentifierLength
        )
        self.name = InputLimits.text(name, maximumLength: InputLimits.appNameLength)
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
        self.text = InputLimits.text(text, maximumLength: InputLimits.finishLineItemLength)
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
    public let parkedAt: Date

    public init(
        id: UUID = UUID(),
        app: AppIdentity,
        parkedAt: Date = Date()
    ) {
        self.id = id
        self.app = app
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
