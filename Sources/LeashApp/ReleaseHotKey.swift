import Carbon.HIToolbox

@MainActor
final class ReleaseHotKey {
    let displayName: String

    private static let signature: OSType = 0x4C534831
    private static let identifier: UInt32 = 1

    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private let action: () -> Void

    static func register(action: @escaping () -> Void) -> ReleaseHotKey? {
        let candidates: [(keyCode: UInt32, displayName: String)] = [
            (UInt32(kVK_ANSI_L), "Control-Option-Command-L"),
            (UInt32(kVK_Escape), "Control-Option-Command-Escape"),
        ]
        for candidate in candidates {
            if let registration = ReleaseHotKey(
                keyCode: candidate.keyCode,
                displayName: candidate.displayName,
                action: action
            ) {
                return registration
            }
        }
        return nil
    }

    private init?(keyCode: UInt32, displayName: String, action: @escaping () -> Void) {
        self.displayName = displayName
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, context in
                guard let event, let context else { return OSStatus(eventNotHandledErr) }
                var identifier = EventHotKeyID()
                let parameterStatus = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard parameterStatus == noErr,
                      identifier.signature == ReleaseHotKey.signature,
                      identifier.id == ReleaseHotKey.identifier else {
                    return OSStatus(eventNotHandledErr)
                }
                let controller = Unmanaged<ReleaseHotKey>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated { controller.action() }
                return noErr
            },
            1,
            &eventType,
            context,
            &eventHandler
        )
        guard installStatus == noErr else {
            if let eventHandler {
                RemoveEventHandler(eventHandler)
                self.eventHandler = nil
            }
            return nil
        }

        let identifier = EventHotKeyID(
            signature: Self.signature,
            id: Self.identifier
        )
        let registrationStatus = RegisterEventHotKey(
            keyCode,
            UInt32(controlKey | optionKey | cmdKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
        guard registrationStatus == noErr, hotKey != nil else {
            if let hotKey {
                UnregisterEventHotKey(hotKey)
                self.hotKey = nil
            }
            if let eventHandler {
                RemoveEventHandler(eventHandler)
                self.eventHandler = nil
            }
            return nil
        }
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
