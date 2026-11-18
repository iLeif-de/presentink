import SwiftUI
import PresentInkCore
import PresentInkLink

struct CompanionView: View {
    @StateObject private var model = CompanionModel()
    @State private var showConnection = false
    @State private var showAbout = false
    @State private var confirmClear = false
    @Environment(\.scenePhase) private var phase
    var body: some View {
        VStack(spacing:0) {
            if model.textPlacement != nil { textEditingHeader } else { header }
            ZStack(alignment:.topLeading) {
                PencilCanvasView(model:model)
                if !model.connected {
                    Label(model.demo ? inkLocalized("Lokale Testfläche · nicht am Mac") : inkLocalized("Nicht verbunden · Zeichnen pausiert"),systemImage:model.demo ? "pencil.and.outline" : "wifi.slash")
                        .font(.caption.weight(.medium)).padding(12).background(.ultraThinMaterial,in:Capsule()).padding(18).allowsHitTesting(false)
                }
            }
            .overlay(alignment: .center) {
                if model.connected, model.image == nil, model.textPlacement == nil {
                    if model.previewState == .live || model.previewState == .starting {
                        ProgressView().padding(16).background(.regularMaterial,in:Capsule()).allowsHitTesting(false)
                    } else { previewInvitation }
                }
            }
            .overlay(alignment: .bottom) {
                if model.textPlacement == nil {
                    ToolDrawerView(model: model, clear: { confirmClear = true })
                        .buttonStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                }
            }
            footer
        }
        // Floating keyboards and Scribble do not reliably occupy the docked
        // keyboard's safe area. Keep normalized canvas geometry stable for both.
        .ignoresSafeArea(.keyboard, edges:.bottom)
        .background(Color(red:0.04,green:0.055,blue:0.09))
        .preferredColorScheme(.dark).tint(.mint)
        .sheet(isPresented:$showConnection) { connectionSheet }
        .alert(inkLocalized("Hinweis"),isPresented:Binding(get:{model.error != nil},set:{ if !$0 { model.error = nil } })) { Button("OK") { model.error = nil } } message: { Text(model.error ?? "") }
        .confirmationDialog(inkLocalized("Alle Annotationen auf dem Mac löschen?"),isPresented:$confirmClear,titleVisibility:.visible) { Button(inkLocalized("Alle löschen"),role:.destructive) { model.cancel(); model.action(.clear) } }
        .onChange(of:phase) { _, new in if new == .active { model.browse() } else if new == .background { model.suspend() } }
        .onChange(of: model.connected) { _, connected in if connected { showConnection = false } }
        .sheet(isPresented: $showAbout) {
            NavigationStack {
                PresentInkAboutView()
                    .navigationTitle(inkLocalized("Über PresentInk"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(inkLocalized("Fertig")) { showAbout = false }
                        }
                    }
            }.presentationSizing(.form)
        }
        .task { model.browse() }
    }
    private var textEditingHeader: some View {
        HStack(spacing:16) {
            Label(inkLocalized("Beschriftung"),systemImage:"text.cursor").font(.headline)
            Spacer()
            Button(inkLocalized("Abbrechen")) { model.cancelText?() }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            Button(inkLocalized("Fertig")) { _ = model.finishText?() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return,modifiers:.command)
        }
        .padding(.horizontal,22).padding(.vertical,14)
    }
    private var previewInvitation: some View {
        VStack(spacing: 12) {
            Image(systemName: "desktopcomputer").font(.largeTitle).foregroundStyle(.mint)
            Text(model.previewState.title).font(.headline)
            Text(model.previewState.detail).font(.callout).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).frame(maxWidth: 380)
            if model.previewState == .starting || model.previewState == .awaitingApproval {
                ProgressView()
            } else {
                Button(model.previewState.isStreaming ? inkLocalized("Vorschau erneut anfordern") : inkLocalized("Mac-Bildschirm anzeigen")) { model.requestPreview() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .padding(.bottom, 100)
    }
    private var header: some View {
        HStack(spacing:16) {
            Image(systemName:"pencil.tip.crop.circle.fill").font(.title).foregroundStyle(.mint)
            VStack(alignment:.leading,spacing:3) {
                Text("PresentInk").font(.headline)
                Text(model.connected ? model.snapshot.display.name : inkLocalized("Companion für deinen Mac")).font(.caption).foregroundStyle(.secondary)
            }
            Button { showAbout = true } label: {
                Image(systemName: "info.circle").font(.title3)
            }.accessibilityLabel(inkLocalized("Über PresentInk"))
            Spacer()
            HStack(spacing:8) {
                Button { model.navigateSlide(.previous) } label: { Image(systemName:"arrow.left").frame(width:36,height:32) }
                    .accessibilityLabel(inkLocalized("Vorherige Folie · Annotationen leeren"))
                    .help(inkLocalized("Vorherige Folie · Annotationen leeren"))
                Button { model.navigateSlide(.next) } label: { Image(systemName:"arrow.right").frame(width:36,height:32) }
                    .accessibilityLabel(inkLocalized("Nächste Folie · Annotationen leeren"))
                    .help(inkLocalized("Nächste Folie · Annotationen leeren"))
            }
            .buttonStyle(.bordered)
            .disabled(!model.canNavigateSlide)
            if model.connected {
                if let state = model.drawingState {
                    Menu {
                        ForEach(state.profiles, id: \.self) { name in
                            Button(name) { model.selectDrawing(DrawingSelection(profile: name)) }
                        }
                    } label: { Label(state.activeProfile ?? inkLocalized("Individuell"), systemImage: "paintpalette") }
                    .buttonStyle(.bordered)
                }
                Toggle(inkLocalized("Mac-Drawer"), isOn: Binding(
                    get: { model.macDrawerVisible ?? false },
                    set: { model.setMacDrawerVisible($0) }))
                    .toggleStyle(.switch).fixedSize()
                    .disabled(model.macDrawerVisible == nil)
                    .accessibilityHint(inkLocalized("Aus blendet den Drawer auf dem Mac einschließlich Griff aus."))
                Label(inkLocalized("Verbunden"),systemImage:"checkmark.shield.fill").font(.caption).foregroundStyle(.mint)
                if model.image == nil, model.previewState != .starting, model.previewState != .awaitingApproval {
                    Button(inkLocalized("Bildschirm anzeigen")) { model.requestPreview() }.buttonStyle(.bordered)
                }
            }
            Button { showConnection = true } label: { Label(model.connected ? inkLocalized("Verbindung") : inkLocalized("Mac verbinden"),systemImage:"desktopcomputer") }.buttonStyle(.bordered)
        }.padding(.horizontal,22).padding(.vertical,14)
    }
    private var footer: some View {
        TimelineView(.periodic(from:.now,by:1)) { timeline in
            HStack {
                Circle().fill(model.connected ? Color.mint : .orange).frame(width:6,height:6)
                Text(model.previewStatus)
                if let date = model.lastFrame, timeline.date.timeIntervalSince(date) > 2 { Text(inkLocalized("· Vorschau älter als 2 s")).foregroundStyle(.orange) }
                Spacer()
                Text(model.constrainShapes ? inkLocalized("Formen fixiert") : inkLocalized("Pencil und Finger zeichnen"))
            }.font(.caption).foregroundStyle(.secondary).padding(.horizontal,22).padding(.vertical,8)
        }
    }
    private var connectionSheet: some View {
        NavigationStack {
            Form {
                Section {
                    Label(model.status,systemImage:model.connected ? "checkmark.shield" : "network")
                    Text(inkLocalized("Nur beim ersten Verbinden den Schlüssel vom Mac eingeben. Bekannte Macs werden wiedererkannt und beim nächsten Öffnen automatisch verbunden.")).foregroundStyle(.secondary)
                }
                if model.connected || model.connecting {
                    Section { Button(inkLocalized("Verbindung trennen"),role:.destructive) { model.disconnect() } }
                } else {
                    Section(inkLocalized("Erste Kopplung: Schlüssel vom Mac")) {
                        TextField(inkLocalized("32 Zeichen"),text:$model.token).textInputAutocapitalization(.never).autocorrectionDisabled().font(.system(.body,design:.monospaced))
                    }
                    Section(inkLocalized("Macs im lokalen Netzwerk")) {
                        if model.hosts.isEmpty { Text(inkLocalized("Suche läuft … Lokales Netzwerk erlauben und die Verbindung am Mac starten.")).foregroundStyle(.secondary) }
                        ForEach(model.hosts) { host in
                            Button { model.connect(to:host) } label: {
                                Label(host.name,systemImage:model.isTrusted(host) ? "checkmark.shield" : "desktopcomputer")
                            }.disabled(!model.isTrusted(host) && model.token.isEmpty)
                        }
                    }
                    Section {
                        Button(inkLocalized("Lokale Testfläche öffnen")) { model.enableDemo(); showConnection = false }
                    } footer: { Text(inkLocalized("Die Testfläche wird nicht an den Mac übertragen. Pencil und Finger sind gleichzeitig verfügbar; der Pencil hat Vorrang.")) }
                }
                if !model.trustedHosts.isEmpty {
                    Section(inkLocalized("Gemerkte Macs")) {
                        ForEach(model.trustedHosts) { host in
                            HStack {
                                Label(host.name, systemImage: "checkmark.shield")
                                Spacer()
                                Button(inkLocalized("Vergessen"), role: .destructive) { model.forgetHost(host.id) }
                            }
                        }
                    }
                }
                Section(inkLocalized("Datenschutz")) {
                    Text(inkLocalized("TLS-verschlüsselt im lokalen Netzwerk. Kein Konto und keine Cloud. Kopplungsschlüssel werden im Schlüsselbund gespeichert; Bildschirminhalte werden nicht aufgezeichnet. Die Bildschirmvorschau muss separat am Mac freigegeben werden. Beim Wechsel in den Hintergrund wird die Verbindung beendet."))
                }
            }.navigationTitle(inkLocalized("Mac verbinden")).toolbar { ToolbarItem(placement:.confirmationAction) { Button(inkLocalized("Fertig")) { showConnection = false } } }
        }.presentationDetents([.large])
    }
}
