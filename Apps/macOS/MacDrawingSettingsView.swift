import SwiftUI
import AppKit
import PresentInkCore

struct MacDrawingSettingsView: View {
    @ObservedObject var session: MacSession
    @State private var draft = DrawingSettings()
    @State private var base = DrawingSettings()
    @State private var editingTool: InkTool = .pen
    @State private var profileName = ""
    @State private var selectedProfile = "Helle Folien"
    @State private var message: String?
    private var dirty: Bool { draft != base }
    private var styleIndex: Int { draft.styles.firstIndex { $0.tool == editingTool } ?? 0 }
    private func colorBinding(_ get: @escaping () -> InkColor, _ set: @escaping (InkColor) -> Void) -> Binding<Color> {
        Binding(get: { let c = get(); return Color(red: c.r, green: c.g, blue: c.b) }, set: { value in
            guard let c = NSColor(value).usingColorSpace(.deviceRGB) else { return }
            set(InkColor(c.redComponent, c.greenComponent, c.blueComponent))
        })
    }
    private func reload() { draft = session.settings; base = draft; message = nil }
    private func save(profile: Bool) {
        do {
            guard session.settings == base else { throw AutomationFailure.unavailable(inkLocalized("Die Einstellungen wurden inzwischen am Mac oder iPad geändert. Bitte neu laden, bevor du speicherst.")) }
            if profile { try session.saveProfile(profileName, settings: draft) }
            else { try session.updateSettings(draft) }
            reload(); message = inkLocalized("Gespeichert und mit dem verbundenen iPad synchronisiert.")
        } catch { message = error.localizedDescription }
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(inkLocalized("Zeichnen nach deinen Vorstellungen")).font(.title2.bold())
                    Text(inkLocalized("Der Mac speichert die Einstellungen. Das iPad übernimmt sie.")).foregroundStyle(.secondary)
                }
                Spacer()
            }.padding(22)
            Divider()
            Form {
                Section(inkLocalized("Profile")) {
                    HStack {
                        Picker(inkLocalized("Profil"), selection: $selectedProfile) {
                            ForEach(session.library.profiles) { Text($0.name).tag($0.name) }
                        }
                        Button(inkLocalized("Anwenden")) {
                            guard !dirty else { message = inkLocalized("Zuerst Änderungen speichern oder neu laden."); return }
                            do { try session.useProfile(selectedProfile); reload() }
                            catch { message = error.localizedDescription }
                        }
                    }
                    Text(inkLocalized("Aktuell: %@", String(describing: (session.library.activeProfile ?? inkLocalized("Individuell"))))).foregroundStyle(.secondary)
                    HStack {
                        TextField(inkLocalized("Profilname (bis 40 Zeichen)"), text: $profileName)
                        Button(inkLocalized("Als Profil speichern")) { save(profile: true) }.disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    Text(inkLocalized("Gleicher Name ersetzt das gespeicherte Profil. Bis zu zwölf Profile, inklusive der Vorlagen.")).font(.caption).foregroundStyle(.secondary)
                }
                Section(inkLocalized("Farbpalette · Reihenfolge gilt für beide Drawer und ⌘1–8")) {
                    ForEach(draft.palette.indices, id: \.self) { index in
                        HStack {
                            ColorPicker(inkLocalized("Farbe %@", String(describing: (index+1))), selection: colorBinding({ draft.palette.indices.contains(index) ? draft.palette[index] : .red }, { if draft.palette.indices.contains(index) { draft.palette[index] = $0 } }), supportsOpacity: false)
                            Text(AutomationValues.hex(draft.palette[index])).font(.system(.caption, design: .monospaced))
                            Button { draft.palette.swapAt(index, index-1) } label: { Image(systemName: "arrow.up") }.disabled(index == 0).help(inkLocalized("Farbe nach vorne"))
                            Button { draft.palette.swapAt(index, index+1) } label: { Image(systemName: "arrow.down") }.disabled(index == draft.palette.count-1).help(inkLocalized("Farbe nach hinten"))
                            Button { draft.palette.remove(at: index) } label: { Image(systemName: "minus.circle") }.disabled(draft.palette.count == 1).help(inkLocalized("Farbe entfernen"))
                        }
                    }
                    Button(inkLocalized("Farbe hinzufügen")) { draft.palette.append(.red) }.disabled(draft.palette.count >= 8)
                }
                Section(inkLocalized("Werkzeug-Einstellungen")) {
                    Picker(inkLocalized("Werkzeug bearbeiten"), selection: $editingTool) { ForEach(InkTool.allCases.filter { $0 != .eraser }) { Text($0.title).tag($0) } }
                    Text(editingTool == .text ? inkLocalized("Schriftgröße in Mac-Punkten") : inkLocalized("Strichstärke in Mac-Punkten")).font(.headline)
                    ColorPicker(inkLocalized("Standardfarbe"), selection: colorBinding({ draft.styles[styleIndex].color }, { draft.styles[styleIndex].color = $0 }), supportsOpacity: false)
                    HStack {
                        Text(inkLocalized("Deckkraft"))
                        Slider(value: $draft.styles[styleIndex].opacity, in: 0.05...1, step: 0.01)
                        Text(draft.styles[styleIndex].opacity.formatted(.percent.precision(.fractionLength(0)))).monospacedDigit().frame(width: 48)
                    }
                    HStack {
                        TextField("Minimum", value: $draft.styles[styleIndex].minimum, format: .number)
                        TextField("Maximum", value: $draft.styles[styleIndex].maximum, format: .number)
                        TextField(inkLocalized("Standard"), value: $draft.styles[styleIndex].width, format: .number)
                    }
                    HStack {
                        ForEach(0..<3) { index in
                            TextField(inkLocalized("Schnellstärke %@", String(describing: (index+1))), value: $draft.styles[styleIndex].quickWidths[index], format: .number)
                        }
                    }
                    Text(inkLocalized("Breiten in logischen Punkten auf dem Mac-Zieldisplay: 0,5–100 pt. Minimum kleiner als Maximum; Standard und Schnellstärken innerhalb des Bereichs. Änderungen betreffen neue Striche. Die Standardfarbe/-breite ist zugleich die zuletzt gewählte Einstellung des Werkzeugs.")).font(.caption).foregroundStyle(.secondary)
                }
                Section(inkLocalized("Pencil-Druck · Stift")) {
                    Toggle(inkLocalized("Stiftbreite durch Pencil-Druck variieren"), isOn: $draft.pressureEnabled)
                    Slider(value: $draft.pressureSensitivity, in: 0...1).disabled(!draft.pressureEnabled)
                    Text(inkLocalized("Wirkung: %@ %. Die resultierende Breite bleibt immer zwischen Werkzeug-Minimum und -Maximum.", String(describing: (Int(draft.pressureSensitivity*100))))).font(.caption).foregroundStyle(.secondary)
                }
                Section(inkLocalized("Werkzeuge im Drawer")) {
                    ForEach(InkTool.allCases) { tool in
                        Toggle(tool.title, isOn: Binding(get: { draft.visibleTools.contains(tool) }, set: { visible in
                            if visible { draft.visibleTools.append(tool) } else { draft.visibleTools.removeAll { $0 == tool } }
                        }))
                    }
                    ForEach(Array(draft.visibleTools.enumerated()), id: \.element) { index, tool in
                        HStack {
                            Text("\(index+1). \(tool.title)"); Spacer()
                            Button { draft.visibleTools.swapAt(index, index-1) } label: { Image(systemName: "arrow.up") }.disabled(index == 0)
                            Button { draft.visibleTools.swapAt(index, index+1) } label: { Image(systemName: "arrow.down") }.disabled(index == draft.visibleTools.count-1)
                        }
                    }
                    Text(inkLocalized("Mindestens ein Werkzeug bleibt sichtbar. Ausgeblendete Werkzeuge sind weiterhin über Menü, Tastatur und Automation erreichbar.")).font(.caption).foregroundStyle(.secondary)
                }
                Section(inkLocalized("Bildschirmfreigabe")) {
                    Toggle(inkLocalized("Vorschau-Anfragen der aktuellen Kopplung ohne PresentInk-Rückfrage erlauben"), isOn: Binding(get: { session.previewPolicy.trusted }, set: { session.setPreviewTrust($0) })).disabled(session.token.isEmpty)
                    Toggle(inkLocalized("Vorschau nach dem Verbinden automatisch starten"), isOn: Binding(get: { session.previewPolicy.autoStart }, set: { session.setPreviewAutoStart($0) })).disabled(!session.previewPolicy.trusted)
                    Text(inkLocalized("Diese beiden Schalter gelten sofort. Zuerst die Host-Verbindung starten. macOS kann weiterhin eine Systemfreigabe verlangen. Bewusstes Pausieren bleibt auch nach erneutem Verbinden wirksam, bis die Vorschau ausdrücklich gestartet oder angefordert wird. Kopplung zurücksetzen widerruft das Vertrauen.")).font(.caption).foregroundStyle(.secondary)
                }
            }.formStyle(.grouped)
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                if let message { Text(message).font(.callout).textSelection(.enabled) }
                HStack {
                    Text(dirty ? inkLocalized("Ungespeicherte Änderungen") : inkLocalized("Zeichen-Einstellungen gespeichert")).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button(inkLocalized("Neu laden")) { reload() }
                    Button(inkLocalized("Sichern & anwenden")) { save(profile: false) }.buttonStyle(.borderedProminent).disabled(!dirty)
                }
            }.padding(18)
        }
        .onAppear { reload() }
        .onChange(of: session.library.current) { _, _ in if !dirty { reload() } }
        .frame(minWidth: 700, minHeight: 640)
    }
}
