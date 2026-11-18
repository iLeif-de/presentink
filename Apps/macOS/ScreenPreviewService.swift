import PresentInkCore
import AppKit
import ScreenCaptureKit
import CoreImage
import ImageIO
import UniformTypeIdentifiers
import PresentInkLink

/// Low-bandwidth prototype: 6 fps, max 1280 px, JPEG; independent TLS video channel.
final class ScreenPreviewService: NSObject, SCStreamOutput, SCStreamDelegate {
    var onFrame: ((Data, UUID) -> Void)?
    var onPublicWindowsChanged: ((Int) -> Void)?
    var onError: ((String) -> Void)?
    private let publicWindowIdentifiers: Set<String> = ["presentink.settings", "presentink.guide", "presentink.shortcuts", "presentink.about"]
    private var filterTask: Task<Void, Never>?
    @MainActor private func publicWindowIDs() -> Set<CGWindowID> {
        let settingsVisible = NSApp.windows.contains { $0.isVisible && $0.identifier?.rawValue == "presentink.settings" }
        return Set(NSApp.windows.filter { window in
            window.isVisible && (publicWindowIdentifiers.contains(window.identifier?.rawValue ?? "") ||
                publicWindowIdentifiers.contains(window.parent?.identifier?.rawValue ?? "") || (settingsVisible && window is NSColorPanel))
        }.map { CGWindowID($0.windowNumber) })
    }
    @MainActor private func makeFilter(displayID: CGDirectDisplayID, content supplied: SCShareableContent? = nil) async throws -> (SCContentFilter, Set<CGWindowID>) {
        let content: SCShareableContent
        if let supplied { content = supplied } else { content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true) }
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else {
            throw NSError(domain:"PresentInk",code:1,userInfo:[NSLocalizedDescriptionKey:inkLocalized("Zieldisplay nicht verfügbar.")])
        }
        let ownApps = content.applications.filter { $0.processID == ProcessInfo.processInfo.processIdentifier }
        guard !ownApps.isEmpty else { throw NSError(domain:"PresentInk",code:2,userInfo:[NSLocalizedDescriptionKey:inkLocalized("PresentInk-Fenster konnten nicht sicher aus der Vorschau ausgeschlossen werden.")]) }
        let allowed = publicWindowIDs()
        let publicWindows = content.windows.filter { allowed.contains($0.windowID) && $0.owningApplication?.processID == ProcessInfo.processInfo.processIdentifier }
        // Exclude our whole app by default. Only explicitly public help/settings windows are exceptions.
        return (SCContentFilter(display: display, excludingApplications: ownApps, exceptingWindows: publicWindows), Set(publicWindows.map(\.windowID)))
    }
    private var stream: SCStream?
    private var streamSourceEpoch: UUID?
    private let queue = DispatchQueue(label:"de.presentink.preview", qos:.userInitiated)
    private let context = CIContext(options:[.cacheIntermediates:false])
    private var generation = UUID()
    private var lastFrame = 0.0
    private var delivering = false
    @MainActor func start(displayID: CGDirectDisplayID, sourceEpoch: UUID) async throws {
        await stop()
        guard CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess() else {
            throw NSError(domain: "PresentInk", code: 3, userInfo: [NSLocalizedDescriptionKey: inkLocalized("Bildschirmaufnahme nicht erlaubt. In Systemeinstellungen → Datenschutz & Sicherheit → Bildschirm- & Systemaudioaufnahme PresentInk erlauben und die Vorschau erneut starten.")])
        }
        let generation = UUID(); self.generation = generation
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly:true)
        guard self.generation == generation else { return }
        guard let display = content.displays.first(where: { $0.displayID == displayID }) else { throw NSError(domain:"PresentInk",code:1,userInfo:[NSLocalizedDescriptionKey:inkLocalized("Zieldisplay nicht verfügbar.")]) }
        let (filter, initialIDs) = try await makeFilter(displayID: displayID, content: content)
        guard self.generation == generation else { return }
        let config = SCStreamConfiguration()
        let scale = min(1,1280.0/Double(display.width))
        config.width = max(2,Int(Double(display.width)*scale)/2*2)
        config.height = max(2,Int(Double(display.height)*scale)/2*2)
        config.minimumFrameInterval = CMTime(value:1,timescale:6)
        config.queueDepth = 3; config.showsCursor = true; config.capturesAudio = false
        config.pixelFormat = kCVPixelFormatType_32BGRA
        let stream = SCStream(filter:filter, configuration:config, delegate:self)
        try stream.addStreamOutput(self, type:.screen, sampleHandlerQueue:queue)
        self.stream = stream; self.streamSourceEpoch = sourceEpoch
        do { try await stream.startCapture() }
        catch { self.stream = nil; throw error }
        if self.generation != generation { try? await stream.stopCapture(); return }
        onPublicWindowsChanged?(initialIDs.count)
        var previousIDs = initialIDs
        filterTask = Task { @MainActor [weak self, weak stream] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(500)) } catch { return }
                guard let self, let stream, self.generation == generation else { return }
                let ids = self.publicWindowIDs()
                guard ids != previousIDs else { continue }
                do {
                    let (filter, resolvedIDs) = try await self.makeFilter(displayID: displayID)
                    guard self.generation == generation, !Task.isCancelled else { return }
                    try await stream.updateContentFilter(filter)
                    previousIDs = resolvedIDs
                    self.onPublicWindowsChanged?(resolvedIDs.count)
                } catch {
                    guard self.generation == generation, !Task.isCancelled else { return }
                    self.onError?(inkLocalized("Vorschaufenster konnten nicht aktualisiert werden: %@", String(describing: (error.localizedDescription))))
                    return
                }
            }
        }
    }
    @MainActor func stop() async {
        filterTask?.cancel(); filterTask = nil
        onPublicWindowsChanged?(0)
        generation = UUID()
        let old = stream; stream = nil; streamSourceEpoch = nil
        if let old { try? await old.stopCapture() }
    }
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.stream === stream else { return }; self.onError?(error.localizedDescription)
        }
    }
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen, sampleBuffer.isValid, let pixel = sampleBuffer.imageBuffer else { return }
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary:false) as? [[SCStreamFrameInfo:Any]],
           let status = attachments.first?[.status] as? Int, status != SCFrameStatus.complete.rawValue { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now-lastFrame >= 0.14 else { return }; lastFrame = now
        guard !delivering else { return }
        let image = CIImage(cvPixelBuffer:pixel)
        guard let cgImage = context.createCGImage(image, from:image.extent) else { return }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1,nil) else { return }
        CGImageDestinationAddImage(destination,cgImage,[kCGImageDestinationLossyCompressionQuality:0.58] as CFDictionary)
        guard CGImageDestinationFinalize(destination), data.length <= 1_500_000 else { return }
        // Backpressure also at the main queue boundary: no unbounded queue of decoded frames.
        guard !delivering else { return }; delivering = true
        let bytes = Data(referencing:data)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if self.stream === stream, let sourceEpoch = self.streamSourceEpoch { self.onFrame?(bytes,sourceEpoch) }
            self.queue.async { self.delivering = false }
        }
    }
}
