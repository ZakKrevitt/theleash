import Carbon.HIToolbox

@MainActor
final class ReleaseHotKey {
    static let displayName = "Control-Option-Command-L"

    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, context in
                guard let context else { return OSStatus(eventNotHandledErr) }
                let controller = Unmanaged<ReleaseHotKey>.fromOpaque(context).takeUnretainedValue()
                MainActor.assumeIsolated { controller.action() }
                return noErr
            },
            1,
            &eventType,
            context,
            &eventHandler
        )

        let identifier = EventHotKeyID(signature: 0x4C534831, id: 1)
        RegisterEventHotKey(
            UInt32(kVK_ANSI_L),
            UInt32(controlKey | optionKey | cmdKey),
            identifier,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }
}
