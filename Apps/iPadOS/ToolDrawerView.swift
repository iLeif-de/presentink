import SwiftUI
import PresentInkCore

/// An overlay: changing drawer state never changes the Pencil canvas's bounds.
struct ToolDrawerView: View {
    @ObservedObject var model: CompanionModel
    let clear: () -> Void
    @State private var compact = false
    @State private var showWidthEditor = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var strengths: [Double] { Array(Set(model.settings.currentStyle.quickWidths)).sorted() }
    private let colorNames = [inkLocalized("Rot"), inkLocalized("Gelb"), inkLocalized("Blau"), inkLocalized("Grün"), inkLocalized("Weiß"), inkLocalized("Graphit")]

    var body: some View {
        Group {
            if model.showTools {
                VStack(spacing: 0) {
                    if compact {
                        compactRow
                    } else {
                        ViewThatFits(in: .horizontal) {
                            fullRow.fixedSize(horizontal: true, vertical: false)
                            // Smaller windows retain full-size hit targets instead of shrinking buttons.
                            VStack(spacing: 6) {
                                HStack(spacing: 8) { toolButtons; separator; actions }
                                HStack(spacing: 8) { colorButtons; separator; strengthButtons; shapeLock }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 22)
                .padding(.bottom, 8)
                .overlay(alignment:.top) { grip }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.12)))
                .shadow(color: .black.opacity(0.22), radius: 16, y: 5)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                reopenButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: model.showTools)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: compact)
        .popover(isPresented: $showWidthEditor) {
            VStack(alignment: .leading, spacing: 16) {
                Text(model.tool == .text ? inkLocalized("Schriftgröße") : inkLocalized("Strichstärke")).font(.headline)
                HStack {
                    Slider(value: Binding(get: { model.width }, set: { model.width = $0 }), in: model.settings.currentStyle.minimum...model.settings.currentStyle.maximum, step: 0.5).accessibilityLabel(inkLocalized("Strichstärke"))
                    Text("\(model.width.formatted(.number.precision(.fractionLength(0...1)))) pt").monospacedDigit().frame(width: 48)
                }
                Button(inkLocalized("Fertig")) { showWidthEditor = false }.frame(maxWidth: .infinity)
            }.padding(24).frame(width: 300)
        }
    }

    private var grip: some View {
        Button { compact.toggle() } label: {
            Image(systemName:compact ? "chevron.up" : "chevron.down")
                .font(.system(size:12,weight:.semibold)).foregroundStyle(.secondary)
                .frame(maxWidth:.infinity).frame(height:22).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(compact ? inkLocalized("Werkzeugpalette ausziehen") : inkLocalized("Werkzeugpalette verkleinern"))
    }

    private var fullRow: some View {
        HStack(spacing: 8) {
            toolButtons
            separator
            colorButtons
            separator
            strengthButtons
            shapeLock
            separator
            actions
        }
    }

    private var compactRow: some View {
        HStack(spacing: 8) {
            toolButtons
            separator
            Button { compact = false } label: {
                HStack(spacing: 8) {
                    Circle().fill(inkColor(model.color)).frame(width: 18, height: 18)
                    Text("\(model.width.formatted(.number.precision(.fractionLength(0...1)))) pt").font(.caption.monospacedDigit())
                }.padding(.horizontal, 8).frame(height: 44)
            }.accessibilityLabel(inkLocalized("Farben und Strichstärken öffnen"))
            actions
        }
    }

    private var toolButtons: some View {
        HStack(spacing: 0) {
            ForEach(model.settings.visibleTools) { tool in
                Button { model.setTool(tool) } label: {
                    Image(systemName: tool.symbol).font(.system(size: 21, weight: .regular))
                        .frame(width: 44, height: 44)
                        .background(model.tool == tool ? Color.mint.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(model.tool == tool ? .mint : .primary)
                .accessibilityLabel(tool.title)
                .accessibilityAddTraits(model.tool == tool ? .isSelected : [])
                .help(tool.title)
            }
        }
    }

    private var colorButtons: some View {
        HStack(spacing: 0) {
            ForEach(Array(model.settings.palette.enumerated()), id: \.offset) { index, color in
                Button { model.color = color } label: {
                    Circle().fill(inkColor(color)).frame(width: 23, height: 23)
                        .overlay(Circle().strokeBorder(.white.opacity(0.2)))
                        .padding(5)
                        .overlay(Circle().stroke(model.color == color ? Color.mint : .clear, lineWidth: 2))
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .accessibilityLabel(AutomationValues.hex(color))
                .accessibilityAddTraits(model.color == color ? .isSelected : [])
            }
        }
    }

    private var strengthButtons: some View {
        HStack(spacing: 0) {
            ForEach(strengths, id: \.self) { strength in
                Button { model.width = strength } label: {
                    Group {
                        if model.tool == .text {
                            let smallest = strengths.min() ?? strength
                            let largest = strengths.max() ?? strength
                            let scale = (strength - smallest) / max(1, largest - smallest)
                            Text("A").font(.system(size: 16 + 14 * scale, weight: .medium))
                        } else {
                            Circle().fill(.primary).frame(width: min(18,strength + 2), height: min(18,strength + 2))
                        }
                    }
                        .frame(width: 44, height: 44)
                        .background(model.width == strength ? Color.mint.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel(model.tool == .text
                    ? "\(inkLocalized("Schriftgröße")) \(strength.formatted(.number.precision(.fractionLength(0...1)))) pt"
                    : inkLocalized("%@ Punkt Strichstärke", String(describing: (strength.formatted(.number.precision(.fractionLength(0...1)))))))
                .accessibilityAddTraits(model.width == strength ? .isSelected : [])
                .help("\(strength.formatted(.number.precision(.fractionLength(0...1)))) pt")
            }
        }
    }

    @ViewBuilder private var shapeLock: some View {
        Button { model.constrainShapes.toggle() } label: {
                Image(systemName: model.constrainShapes ? "aspectratio.fill" : "aspectratio")
                    .frame(width: 44, height: 44)
                    .background(model.constrainShapes ? Color.mint.opacity(0.2) : .clear, in: RoundedRectangle(cornerRadius: 12))
            }
            .accessibilityLabel(inkLocalized("Quadrat, Kreis und 45-Grad-Raster"))
            .accessibilityValue(model.constrainShapes ? inkLocalized("Aktiv") : inkLocalized("Inaktiv"))
            .help(inkLocalized("Proportional ändern / 45-Grad-Raster"))
    }

    private var actions: some View {
        HStack(spacing: 0) {
            Button { model.clearAnnotations() } label: {
                Image(systemName:"trash").frame(width:44,height:44)
            }.accessibilityLabel(inkLocalized("Annotationen leeren"))
                .help(inkLocalized("Annotationen leeren · rückgängig möglich"))
                .disabled(!model.canClearAnnotations)
            Button {
                model.cancel(); model.action(.visibility(!model.snapshot.overlayVisible))
            } label: {
                Image(systemName:model.snapshot.overlayVisible ? "eye.slash" : "eye").frame(width:44,height:44)
            }.accessibilityLabel(model.snapshot.overlayVisible ? inkLocalized("Annotationen ausblenden") : inkLocalized("Annotationen zeigen"))
                .help(model.snapshot.overlayVisible ? inkLocalized("Annotationen ausblenden") : inkLocalized("Annotationen zeigen"))
                .disabled(!model.drawable)
            Menu {
                Button(inkLocalized("Rückgängig"), systemImage: "arrow.uturn.backward") { model.cancel(); model.action(.undo) }
                    .disabled(!model.snapshot.canUndo)
                Button(inkLocalized("Wiederholen"), systemImage: "arrow.uturn.forward") { model.cancel(); model.action(.redo) }
                    .disabled(!model.snapshot.canRedo)
                Divider()
                if let state = model.drawingState {
                    Menu(inkLocalized("Profil")) {
                        ForEach(state.profiles, id: \.self) { name in
                            Button(name) { model.selectDrawing(DrawingSelection(profile: name)) }
                        }
                    }
                }
                Button(inkLocalized("Strichstärke genau …"), systemImage: "slider.horizontal.3") { showWidthEditor = true }
                Button(model.constrainShapes ? inkLocalized("Formfixierung ausschalten") : inkLocalized("Formfixierung einschalten"), systemImage: "aspectratio") { model.constrainShapes.toggle() }
                Button(model.snapshot.overlayVisible ? inkLocalized("Annotationen ausblenden") : inkLocalized("Annotationen zeigen"), systemImage: model.snapshot.overlayVisible ? "eye.slash" : "eye") {
                    model.cancel(); model.action(.visibility(!model.snapshot.overlayVisible))
                }
                Toggle(inkLocalized("Mac-Drawer sichtbar"), isOn: Binding(
                    get: { model.macDrawerVisible ?? false },
                    set: { model.setMacDrawerVisible($0) }))
                    .disabled(!model.connected || model.macDrawerVisible == nil)
                Divider()
                Button(inkLocalized("Alle Annotationen löschen …"), systemImage: "trash", role: .destructive, action: clear)
            } label: {
                Image(systemName: "ellipsis").font(.title3).frame(width: 44, height: 44)
            }.accessibilityLabel(inkLocalized("Weitere Zeichenaktionen"))
            Button { model.showTools = false } label: {
                Image(systemName: "chevron.down").frame(width: 44, height: 44)
            }.accessibilityLabel(inkLocalized("Werkzeugpalette verstecken"))
        }
    }

    private var reopenButton: some View {
        Button { compact = false; model.showTools = true } label: {
            VStack(spacing: 5) {
                Image(systemName:"chevron.up").font(.system(size:12,weight:.semibold)).foregroundStyle(.secondary)
                HStack(spacing: 9) {
                    Image(systemName: model.tool.symbol)
                    Circle().fill(inkColor(model.color)).frame(width: 12, height: 12)
                    Text("\(model.width.formatted(.number.precision(.fractionLength(0...1)))) pt").font(.caption.monospacedDigit())
                }
            }
            .padding(.horizontal, 18).padding(.vertical, 10)
            .frame(minHeight: 44)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(.white.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(inkLocalized("Werkzeugpalette öffnen. %@, %@ Punkt", String(describing: (model.tool.title)), String(describing: (model.width.formatted(.number.precision(.fractionLength(0...1)))))))
        .simultaneousGesture(DragGesture(minimumDistance: 12).onEnded { value in
            if value.translation.height < -15 { compact = false; model.showTools = true }
        })
    }

    private var separator: some View { Rectangle().fill(.secondary.opacity(0.25)).frame(width: 1, height: 26) }
    private func inkColor(_ color: InkColor) -> Color { Color(red: color.r, green: color.g, blue: color.b) }
}
