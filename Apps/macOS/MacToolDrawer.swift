import AppKit
import SwiftUI
import Combine
import PresentInkCore

enum MacDrawerPresentation { case expanded, compact, hidden, invisible }

final class MacDrawerState: ObservableObject {
    @Published var presentation: MacDrawerPresentation = .expanded { didSet { presentationChanged?() } }
    var presentationChanged: (() -> Void)?
    @Published var settings = DrawingSettings()
    @Published var tool: InkTool = .pen
    @Published var color = InkColor.red
    @Published var width = 4.0
    @Published var annotationsVisible = true
    var toggleAnnotations: (() -> Void)?
    @Published var drawing = false
    var selectTool: ((InkTool) -> Void)?
    var selectColor: ((InkColor) -> Void)?
    var selectWidth: ((Double) -> Void)?
    var operate: (() -> Void)?
    var clear: (() -> Void)?
    var previousSlide: (() -> Void)?
    var nextSlide: (() -> Void)?
    @Published var canClear = false
    @Published var canNavigate = true
    @Published var error: String?
}

/// Nonactivating panel: tool clicks keep keyboard focus with the drawing window/presentation.
final class MacToolDrawerController {
    let panel: NSPanel
    private let state: MacDrawerState
    private var subscription: AnyCancellable?
    private var settingsSubscription: AnyCancellable?
    private var screen: NSScreen?

    init(state: MacDrawerState) {
        self.state = state
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = inkLocalized("PresentInk · Werkzeug-Drawer")
        panel.isReleasedWhenClosed = false
        panel.backgroundColor = .clear; panel.isOpaque = false; panel.hasShadow = false
        panel.level = .statusBar; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .canJoinAllApplications, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: MacToolDrawerView(state: state))
        settingsSubscription = state.$settings.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { guard let self else { return }; self.position(presentation: self.state.presentation, animated: false) }
        }
        subscription = state.$presentation.dropFirst().sink { [weak self] value in
            // @Published emits before its value changes; render/resize after the state update.
            DispatchQueue.main.async {
                guard let self, self.state.presentation == value else { return }
                self.position(presentation: value, animated: true)
            }
        }
    }
    func move(to screen: NSScreen) {
        self.screen = screen; position(presentation: state.presentation, animated: false)
    }
    func show() {
        state.presentation = .expanded
        position(presentation: .expanded, animated: false); panel.orderFrontRegardless()
    }
    func toggle() { state.presentation = (state.presentation == .hidden || state.presentation == .invisible) ? .expanded : .hidden }
    func close() { subscription = nil; panel.orderOut(nil) }
    private func position(presentation: MacDrawerPresentation, animated: Bool) {
        guard presentation != .invisible else { panel.orderOut(nil); return }
        guard let screen else { return }
        let available = screen.visibleFrame
        let width: CGFloat
        let height: CGFloat
        let toolWidth = CGFloat(state.settings.visibleTools.count + 1) * 35 - 1
        let colorWidth = CGFloat(state.settings.palette.count) * 30
        let sizeWidth = CGFloat(Set(state.settings.currentStyle.quickWidths).count) * 32
        let insets: CGFloat = 42 // SwiftUI content padding plus the material's outer margin.
        let actionsWidth: CGFloat = 174 // Five 34-point actions and four one-point gaps.
        let fullWidth = toolWidth + colorWidth + sizeWidth + actionsWidth + 2 + 45 + insets
        let availableWidth = max(1, available.width - 32)
        switch presentation {
        case .expanded:
            if fullWidth <= availableWidth { width = fullWidth; height = 72 }
            else {
                width = min(availableWidth, max(toolWidth + actionsWidth + 9, colorWidth + 1 + sizeWidth + 18) + insets)
                height = 112
            }
        case .compact: width = min(toolWidth + 72 + actionsWidth + 1 + 24 + insets, availableWidth); height = 72
        case .hidden: width = 142; height = 52
        case .invisible: return
        }
        let rect = NSRect(x: available.midX-width/2, y: available.minY+14, width: width, height: height)
        panel.setFrame(rect, display: true, animate: animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
        panel.orderFrontRegardless()
    }
}

private struct MacToolDrawerView: View {
    @ObservedObject var state: MacDrawerState
    var body: some View {
        Group {
            if state.presentation == .invisible { EmptyView() }
            else if state.presentation == .hidden { reopen }
            else {
                VStack(spacing: 0) {
                    grip
                    if state.presentation == .compact {
                        HStack(spacing: 8) {
                            tools
                            divider
                            Button { state.presentation = .expanded } label: {
                                HStack(spacing: 7) {
                                    Circle().fill(color(state.color)).frame(width: 13, height: 13)
                                    Text("\(state.width.formatted(.number.precision(.fractionLength(0...1)))) pt").font(.caption.monospacedDigit())
                                }.frame(width: 72, height: 34)
                            }.drawerHelp(inkLocalized("Farben und Strichstärken öffnen") + " · ⇧⌘D\n" + inkLocalized("Menükürzel bei aktiver PresentInk-App"))
                            hide
                        }
                    } else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 9) { tools; divider; colors; divider; widths; hide }
                                .fixedSize(horizontal: true, vertical: false)
                            VStack(spacing: 6) {
                                HStack(spacing: 9) { tools; hide }
                                HStack(spacing: 9) { colors; divider; widths }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 19))
                .overlay(RoundedRectangle(cornerRadius: 19).strokeBorder(.primary.opacity(0.12)))
            }
        }
        .buttonStyle(.plain)
        .padding(5)
        .alert(inkLocalized("Hinweis"),isPresented:Binding(get:{state.error != nil},set:{ if !$0 { state.error = nil } })) {
            Button("OK") { state.error = nil }
        } message: { Text(state.error ?? "") }
    }
    private var grip: some View {
        Button { state.presentation = .hidden } label: {
            Image(systemName:"chevron.down").font(.system(size:11,weight:.semibold)).foregroundStyle(.secondary)
                .frame(maxWidth: .infinity).frame(height: 20).contentShape(Rectangle())
        }
        .drawerHelp(inkLocalized("Auf Griff minimieren · ⌃⌥W"))
        .accessibilityLabel(inkLocalized("Drawer auf Griff minimieren"))
    }

    private var tools: some View {
        HStack(spacing: 1) {
            Button { state.operate?() } label: {
                Image(systemName: "cursorarrow").frame(width: 34, height: 34)
                    .background(!state.drawing ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 9))
            }.drawerHelp(inkLocalized("Bedienen · Escape / V") + "\n" + inkLocalized("Zeichenmodus umschalten") + " · ⌃⌥A").accessibilityLabel(inkLocalized("Bedienen"))
                .accessibilityAddTraits(!state.drawing ? .isSelected : [])
            ForEach(state.settings.visibleTools) { tool in
                Button { state.selectTool?(tool) } label: {
                    Image(systemName: tool.symbol).font(.system(size: 17))
                        .frame(width: 34, height: 34)
                        .background(state.drawing && state.tool == tool ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 9))
                }.drawerHelp(tool.title + " · " + shortcut(tool) + "\n" + inkLocalized("Im Zeichenmodus; Menü:") + " ⌥⌘" + shortcut(tool)).accessibilityLabel(tool.title)
                    .accessibilityAddTraits(state.drawing && state.tool == tool ? .isSelected : [])
            }
        }
    }
    private var colors: some View {
        HStack(spacing: 0) {
            ForEach(Array(state.settings.palette.enumerated()), id: \.offset) { index, value in
                Button { state.selectColor?(value) } label: {
                    Circle().fill(color(value)).frame(width: 17, height: 17)
                        .overlay(Circle().strokeBorder(.primary.opacity(0.15)))
                        .padding(4)
                        .overlay(Circle().stroke(state.color == value ? Color.accentColor : .clear, lineWidth: 2))
                        .frame(width: 30, height: 34).contentShape(Rectangle())
                }.drawerHelp("\(AutomationValues.hex(value)) · ⌘\(index+1)\n" + inkLocalized("Menükürzel bei aktiver PresentInk-App")).accessibilityLabel(AutomationValues.hex(value))
                    .accessibilityAddTraits(state.color == value ? .isSelected : [])
            }
        }
    }
    private var widths: some View {
        HStack(spacing: 0) {
            ForEach(Array(Set(state.settings.currentStyle.quickWidths)).sorted(), id: \.self) { value in
                Button { state.selectWidth?(value) } label: {
                    Group {
                        if state.tool == .text {
                            let sizes = state.settings.currentStyle.quickWidths
                            let smallest = sizes.min() ?? value
                            let largest = sizes.max() ?? value
                            let scale = (value - smallest) / max(1, largest - smallest)
                            Text("A").font(.system(size: 14 + 12 * scale, weight: .medium))
                        } else {
                            Circle().fill(.primary).frame(width: min(16,value+2), height: min(16,value+2))
                        }
                    }
                        .frame(width: 32, height: 34)
                        .background(state.width == value ? Color.accentColor.opacity(0.18) : .clear, in: RoundedRectangle(cornerRadius: 9))
                }.drawerHelp((state.tool == .text ? inkLocalized("Schriftgröße") : inkLocalized("Strichstärke")) + " \(value.formatted(.number.precision(.fractionLength(0...1)))) pt\n⌘+ / ⌘− · " + inkLocalized("Menükürzel bei aktiver PresentInk-App"))
                    .accessibilityLabel(state.tool == .text
                        ? "\(inkLocalized("Schriftgröße")) \(value.formatted(.number.precision(.fractionLength(0...1)))) pt"
                        : inkLocalized("%@ Punkt Strichstärke", String(describing: (value.formatted(.number.precision(.fractionLength(0...1)))))))
                    .accessibilityAddTraits(state.width == value ? .isSelected : [])
            }
        }
    }
    private var hide: some View {
        HStack(spacing: 1) {
            Button { state.previousSlide?() } label: { Image(systemName:"arrow.left").frame(width:34,height:34) }
                .drawerHelp(inkLocalized("Vorherige Folie · Annotationen leeren"))
                .accessibilityLabel(inkLocalized("Vorherige Folie · Annotationen leeren")).disabled(!state.canNavigate)
            Button { state.nextSlide?() } label: { Image(systemName:"arrow.right").frame(width:34,height:34) }
                .drawerHelp(inkLocalized("Nächste Folie · Annotationen leeren"))
                .accessibilityLabel(inkLocalized("Nächste Folie · Annotationen leeren")).disabled(!state.canNavigate)
            Button { state.clear?() } label: { Image(systemName:"trash").frame(width:34,height:34) }
                .drawerHelp(inkLocalized("Annotationen leeren · rückgängig möglich") + " · ⇧⌘⌫")
                .accessibilityLabel(inkLocalized("Annotationen leeren")).disabled(!state.canClear)
            Button { state.toggleAnnotations?() } label: {
                Image(systemName: state.annotationsVisible ? "eye.slash" : "eye").frame(width:34,height:34)
            }.drawerHelp((state.annotationsVisible ? inkLocalized("Annotationen ausblenden") : inkLocalized("Annotationen zeigen")) + " · ⇧⌘H\n" + inkLocalized("Menükürzel bei aktiver PresentInk-App"))
                .accessibilityLabel(state.annotationsVisible ? inkLocalized("Annotationen ausblenden") : inkLocalized("Annotationen zeigen"))

            Button { state.presentation = .invisible } label: {
                Image(systemName: "xmark").frame(width: 34, height: 34)
            }.drawerHelp(inkLocalized("Vollständig ausblenden · mit ⌃⌥W wieder öffnen")).accessibilityLabel(inkLocalized("Mac-Drawer vollständig ausblenden"))
        }
    }
    private var reopen: some View {
        Button { state.presentation = .expanded } label: {
            VStack(spacing: 4) {
                Image(systemName:"chevron.up").font(.system(size:11,weight:.semibold)).foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: state.drawing ? state.tool.symbol : "cursorarrow")
                    Circle().fill(color(state.color)).frame(width: 11, height: 11)
                    Text("\(state.width.formatted(.number.precision(.fractionLength(0...1)))) pt").font(.caption.monospacedDigit())
                }
            }.frame(width: 128, height: 38)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(.primary.opacity(0.12)))
        }.drawerHelp(inkLocalized("Drawer öffnen · ⌃⌥W")).accessibilityLabel(inkLocalized("Werkzeug-Drawer öffnen"))
            .simultaneousGesture(DragGesture(minimumDistance: 12).onEnded { value in
                if value.translation.height < -15 { state.presentation = .expanded }
            })
    }
    private func shortcut(_ tool: InkTool) -> String {
        switch tool {
        case .pen: "P"
        case .marker: "H"
        case .line: "L"
        case .arrow: "A"
        case .rectangle: "R"
        case .ellipse: "O"
        case .eraser: "E"
        case .text: "T"
        }
    }
    private var divider: some View { Rectangle().fill(.secondary.opacity(0.25)).frame(width: 1, height: 23) }
    private func color(_ value: InkColor) -> Color { Color(red: value.r, green: value.g, blue: value.b) }
}

/// Native tooltips complement SwiftUI help on our nonactivating panel.
/// The background must never intercept toolbar clicks or drawing gestures.
private struct DrawerTooltip: NSViewRepresentable {
    let text: String
    final class TooltipView: NSView {
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }
    func makeNSView(context: Context) -> TooltipView { TooltipView() }
    func updateNSView(_ view: TooltipView, context: Context) { view.toolTip = text }
}
private extension View {
    func drawerHelp(_ text: String) -> some View {
        help(text).background(DrawerTooltip(text: text).allowsHitTesting(false))
    }
}
