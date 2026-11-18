import AppKit
import SwiftUI
import PresentInkCore

private final class TextEntryPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class MacTextEntryController {
    private var panel: NSPanel?
    private var presentationLevel: NSWindow.Level = .statusBar
    func setPresentationLevel(_ level: NSWindow.Level) {
        presentationLevel = level; panel?.level = level
    }
    func show(insert: @escaping (String) throws -> Void) {
        panel?.close()
        let panel = TextEntryPanel(contentRect:NSRect(x:0,y:0,width:440,height:280),
                                   styleMask:[.titled,.closable,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.title = inkLocalized("PresentInk · Text einfügen")
        panel.isReleasedWhenClosed = false; panel.hidesOnDeactivate = false
        panel.level = presentationLevel
        panel.collectionBehavior = [.canJoinAllSpaces,.canJoinAllApplications,.fullScreenAuxiliary,.ignoresCycle]
        panel.contentView = NSHostingView(rootView: MacTextEntryView(insert:insert,close:{ [weak panel] in panel?.close() }))
        let cursor = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(cursor) } ?? NSScreen.main
        if let frame = screen?.visibleFrame {
            panel.setFrameOrigin(NSPoint(x:min(max(frame.minX,cursor.x),frame.maxX-440),y:min(max(frame.minY,cursor.y-280),frame.maxY-280)))
        } else { panel.center() }
        self.panel = panel
        panel.makeKeyAndOrderFront(nil)
    }
}

private struct MacTextEntryView: View {
    let insert: (String) throws -> Void
    let close: () -> Void
    @State private var text = ""
    @State private var error: String?
    @FocusState private var focused: Bool
    var body: some View {
        VStack(alignment:.leading,spacing:12) {
            Text(inkLocalized("Beschriftung an dieser Position")).font(.headline)
            TextEditor(text:$text).font(.body).focused($focused)
                .frame(minHeight:130).border(.quaternary)
                .accessibilityLabel(inkLocalized("Beschriftung"))
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
            HStack {
                Text(inkLocalized("%@/2000 · maximal 20 Zeilen", String(describing: (text.count)))).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button(inkLocalized("Abbrechen"),action:close).keyboardShortcut(.cancelAction)
                Button(inkLocalized("Einfügen")) {
                    do { try insert(text); close() } catch { self.error = error.localizedDescription }
                }.keyboardShortcut(.return,modifiers:.command).disabled(!InkTextLayout.valid(text))
            }
        }.padding(18).frame(width:440,height:280)
        .onAppear { focused = true }
    }
}
