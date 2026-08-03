import SwiftUI
import LeashCore

private enum Palette {
    static let paper = Color(red: 0.95, green: 0.94, blue: 0.90)
    static let panel = Color(red: 0.99, green: 0.98, blue: 0.95)
    static let ink = Color(red: 0.12, green: 0.13, blue: 0.11)
    static let muted = Color(red: 0.43, green: 0.44, blue: 0.40)
    static let accent = Color(red: 0.90, green: 0.33, blue: 0.21)
    static let acid = Color(red: 0.85, green: 0.98, blue: 0.39)
}

struct LeashMenuView: View {
    @ObservedObject var coordinator: LeashCoordinator

    var body: some View {
        VStack(spacing: 0) {
            header
            if coordinator.session == nil {
                SetupView(coordinator: coordinator)
            } else {
                ActiveSessionView(coordinator: coordinator)
            }
        }
        .frame(width: 390)
        .background(Palette.paper)
        .foregroundStyle(Palette.ink)
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(spacing: 10) {
            LeashGlyph(size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("LEASH")
                    .font(.system(size: 11, weight: .black))
                    .tracking(1.5)
                Text("Stay with the thing.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            if coordinator.session != nil {
                Circle()
                    .fill(Palette.accent)
                    .frame(width: 9, height: 9)
                    .shadow(color: Palette.accent.opacity(0.28), radius: 0, x: 0, y: 0)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }
}

private struct SetupView: View {
    @ObservedObject var coordinator: LeashCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            Text("What are you doing?")
                .font(.system(size: 28, weight: .bold))
                .tracking(-1)

            field("Task") {
                TextField("Finish the project brief", text: $coordinator.taskDraft)
                    .textFieldStyle(.plain)
            }

            field("Done when", suffix: "optional") {
                TextField("The draft is sent to Maya", text: $coordinator.doneWhenDraft)
                    .textFieldStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("When I wander")
                    .font(.system(size: 12, weight: .bold))
                HStack(spacing: 8) {
                    ForEach(LeashMode.allCases, id: \.self) { mode in
                        ModeButton(
                            mode: mode,
                            selected: coordinator.mode == mode,
                            action: { coordinator.mode = mode }
                        )
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Apps inside the leash")
                        .font(.system(size: 12, weight: .bold))
                    Spacer()
                    if let anchor = coordinator.lastExternalApp {
                        Text("Anchor: \(anchor.name)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                    }
                }

                ScrollView {
                    LazyVStack(spacing: 3) {
                        ForEach(coordinator.runningApps) { app in
                            AppToggleRow(
                                app: app,
                                icon: coordinator.icon(for: app),
                                selected: coordinator.isSelected(app),
                                locked: app.bundleIdentifier == coordinator.lastExternalApp?.bundleIdentifier,
                                action: { coordinator.toggleAllowed(app) }
                            )
                        }
                    }
                }
                .frame(height: 130)
                .padding(6)
                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.1)))
            }

            HStack(spacing: 9) {
                Picker("Duration", selection: $coordinator.durationMinutes) {
                    Text("15 min").tag(15)
                    Text("25 min").tag(25)
                    Text("45 min").tag(45)
                    Text("60 min").tag(60)
                    Text("90 min").tag(90)
                }
                .labelsHidden()
                .frame(width: 95)

                Button("Start leash") { coordinator.startSession() }
                    .buttonStyle(PrimaryButtonStyle())
            }

            if let error = coordinator.formError {
                Text(error)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.accent)
            }

            if !coordinator.accessibilityTrusted {
                Button("Enable focused window awareness") { coordinator.requestAccessibility() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                    .help("Optional. Adds window titles to Later. App-level enforcement already works.")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func field<Content: View>(
        _ title: String,
        suffix: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 4) {
                Text(title).fontWeight(.bold)
                if let suffix {
                    Text(suffix).foregroundStyle(Palette.muted)
                }
            }
            .font(.system(size: 12))
            content()
                .padding(.horizontal, 11)
                .frame(height: 42)
                .background(Palette.panel, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.12)))
        }
    }
}

private struct ModeButton: View {
    let mode: LeashMode
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(mode.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(mode.detail)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .topLeading)
            .padding(10)
            .background(Palette.panel)
            .overlay(alignment: .bottom) {
                if selected { Rectangle().fill(Palette.acid).frame(height: 4) }
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(selected ? Palette.ink : Color.black.opacity(0.1), lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AppToggleRow: View {
    let app: AppIdentity
    let icon: NSImage
    let selected: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 22, height: 22)
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                Spacer()
                Image(systemName: locked ? "anchor.fill" : selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Palette.ink : Palette.muted.opacity(0.55))
            }
            .padding(.horizontal, 7)
            .frame(height: 34)
            .background(selected ? Palette.acid.opacity(0.28) : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }
}

private struct ActiveSessionView: View {
    @ObservedObject var coordinator: LeashCoordinator

    var body: some View {
        VStack(spacing: 16) {
            if let session = coordinator.session {
                VStack(alignment: .leading, spacing: 9) {
                    Text("RIGHT NOW")
                        .font(.system(size: 10, weight: .black))
                        .tracking(1.4)
                        .foregroundStyle(Palette.muted)
                    Text(session.task)
                        .font(.system(size: 27, weight: .bold))
                        .tracking(-0.8)
                    if !session.doneWhen.isEmpty {
                        Text("Done: \(session.doneWhen)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Palette.muted)
                    }
                    Divider().padding(.vertical, 4)
                    HStack(alignment: .firstTextBaseline) {
                        Text(coordinator.remainingText)
                            .font(.system(size: 30, weight: .black, design: .monospaced))
                        Spacer()
                        Text("\(session.catchCount) \(session.catchCount == 1 ? "catch" : "catches")")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Palette.muted)
                    }
                    HStack(spacing: 5) {
                        Image(systemName: "anchor.fill")
                        Text(session.anchor.name)
                        Text("•")
                        Text(session.mode.title)
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Palette.muted)
                }
                .padding(18)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Palette.acid)
                            .offset(x: 6, y: 6)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Palette.panel)
                    }
                }
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Palette.ink, lineWidth: 1.5))

                Button("Return to task") { coordinator.returnToTask() }
                    .buttonStyle(PrimaryButtonStyle())

                if let current = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                   !session.allowedBundleIdentifiers.contains(current),
                   current != Bundle.main.bundleIdentifier {
                    Button("Allow current app for this leash") { coordinator.allowCurrentApp() }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }

                ParkedList(coordinator: coordinator)

                Button("End leash") { coordinator.endSession() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

private struct ParkedList: View {
    @ObservedObject var coordinator: LeashCoordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("LATER  \(coordinator.parked.count)")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                Spacer()
                if !coordinator.parked.isEmpty {
                    Button("Clear") { coordinator.clearParked() }
                        .buttonStyle(.plain)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Palette.muted)
                }
            }

            if coordinator.parked.isEmpty {
                Text("Distractions you catch will wait here.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Palette.muted)
            } else {
                ForEach(coordinator.parked.prefix(4)) { item in
                    HStack(spacing: 8) {
                        Image(nsImage: coordinator.icon(for: item.app))
                            .resizable()
                            .frame(width: 20, height: 20)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.app.name)
                                .font(.system(size: 11, weight: .bold))
                            if let title = item.windowTitle, !title.isEmpty {
                                Text(title)
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(Palette.muted)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Button {
                            coordinator.removeParked(item)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Palette.muted)
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(.top, 6)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 42)
            .background(configuration.isPressed ? Palette.muted : Palette.ink)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
