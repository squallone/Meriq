import AppKit
import SwiftUI
import WebKit

@MainActor
final class MermaidRenderer: ObservableObject {
    @Published private(set) var statusMessage = "Create or open a diagram to begin rendering."
    @Published private(set) var isError = false

    let webView: WKWebView
    var statusObserver: ((String, Bool) -> Void)?
    var previewEditHandler: ((MermaidPreviewEditRequest) -> Void)?

    private let previewEngine: MermaidRenderEngine
    private let exportEngine: MermaidRenderEngine
    private var currentDraft: DiagramDraft?
    private var currentEditableTokens: [MermaidEditableToken] = []

    init() {
        let previewEngine = MermaidRenderEngine()

        self.previewEngine = previewEngine
        self.exportEngine = MermaidRenderEngine()
        self.webView = previewEngine.webView

        previewEngine.statusHandler = { [weak self] message, isError in
            self?.setStatus(message, isError: isError)
        }
        previewEngine.previewEditHandler = { [weak self] request in
            self?.previewEditHandler?(request)
        }
    }

    var availableThemes: [MermaidThemePreset] {
        MermaidThemePreset.all
    }

    var currentTheme: MermaidThemePreset {
        MermaidThemePreset.preset(id: currentDraft?.previewThemeID ?? MermaidThemePreset.defaultPreset.id)
    }

    func apply(draft: DiagramDraft, shouldRender: Bool = true, editableTokens: [MermaidEditableToken] = []) {
        currentDraft = DiagramDraft(
            id: draft.id,
            name: draft.name,
            source: Self.sanitizedSource(draft.source),
            previewThemeID: draft.previewThemeID,
            exportBackground: draft.exportBackground,
            isFavorite: draft.isFavorite
        )
        currentEditableTokens = editableTokens

        if shouldRender {
            renderPreview()
        }
    }

    func clear() {
        currentDraft = nil
        setStatus("Create or open a diagram to begin rendering.", isError: false)
    }

    func renderPreview() {
        guard let draft = currentDraft else {
            setStatus("Choose a diagram before rendering.", isError: true)
            return
        }

        setStatus("Rendering diagram…", isError: false)

        let request = MermaidPreviewRequest(
            source: draft.source,
            theme: MermaidThemePreset.preset(id: draft.previewThemeID),
            padding: 18,
            editableTokens: currentEditableTokens
        )

        previewEngine.renderPreview(request) { [weak self] result in
            guard case .failure(let error) = result else {
                return
            }

            self?.setStatus("Could not render the diagram: \(error.localizedDescription)", isError: true)
        }
    }

    func setPreviewZoom(_ scale: CGFloat, animated: Bool = true) {
        previewEngine.setPreviewZoom(scale, animated: animated)
    }

    func copySVGToClipboard(scale: Double = 2.0) {
        guard currentDraft != nil else { return }
        setStatus("Preparing SVG export…", isError: false)

        exportEngine.exportSVG(buildExportRequest(scale: scale)) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(payload.svg, forType: .string)
                self.setStatus("Copied SVG with the current export options.", isError: false)
            case .failure(let error):
                self.setStatus("Could not export SVG: \(error.localizedDescription)", isError: true)
            }
        }
    }

    func copyImageToClipboard(scale: Double = 2.0) {
        guard currentDraft != nil else { return }
        setStatus("Preparing PNG export…", isError: false)

        exportEngine.exportPNG(buildExportRequest(scale: scale)) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                do {
                    let image = try self.pngImage(from: payload)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.writeObjects([image])
                    self.setStatus("Copied PNG with the current export options.", isError: false)
                } catch {
                    self.setStatus("Could not copy the PNG export: \(error.localizedDescription)", isError: true)
                }
            case .failure(let error):
                self.setStatus("Could not export PNG: \(error.localizedDescription)", isError: true)
            }
        }
    }

    func exportSVGToFile(scale: Double = 2.0) {
        guard currentDraft != nil else { return }
        guard let destinationURL = chooseDestinationURL(for: .svg) else {
            setStatus("SVG export cancelled.", isError: false)
            return
        }

        setStatus("Preparing SVG export…", isError: false)

        exportEngine.exportSVG(buildExportRequest(scale: scale)) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                do {
                    try payload.svg.write(to: destinationURL, atomically: true, encoding: .utf8)
                    self.setStatus("Saved SVG to \(destinationURL.lastPathComponent).", isError: false)
                } catch {
                    self.setStatus("Could not save the SVG: \(error.localizedDescription)", isError: true)
                }
            case .failure(let error):
                self.setStatus("Could not export SVG: \(error.localizedDescription)", isError: true)
            }
        }
    }

    func exportPNGToFile(scale: Double = 2.0) {
        guard currentDraft != nil else { return }
        guard let destinationURL = chooseDestinationURL(for: .png) else {
            setStatus("PNG export cancelled.", isError: false)
            return
        }

        setStatus("Preparing PNG export…", isError: false)

        exportEngine.exportPNG(buildExportRequest(scale: scale)) { [weak self] result in
            guard let self else { return }

            switch result {
            case .success(let payload):
                do {
                    try self.pngData(from: payload).write(to: destinationURL)
                    self.setStatus("Saved PNG to \(destinationURL.lastPathComponent).", isError: false)
                } catch {
                    self.setStatus("Could not save the PNG: \(error.localizedDescription)", isError: true)
                }
            case .failure(let error):
                self.setStatus("Could not export PNG: \(error.localizedDescription)", isError: true)
            }
        }
    }

    func setStatus(_ message: String, isError: Bool) {
        statusMessage = message
        self.isError = isError
        statusObserver?(message, isError)
    }

    func copyToClipboard(variant: MermaidExportVariant, scale: Double) {
        switch variant {
        case .svg:
            copySVGToClipboard(scale: scale)
        case .png:
            copyImageToClipboard(scale: scale)
        }
    }

    func exportToFile(variant: MermaidExportVariant, scale: Double) {
        switch variant {
        case .svg:
            exportSVGToFile(scale: scale)
        case .png:
            exportPNGToFile(scale: scale)
        }
    }

    private func buildExportRequest(scale: Double) -> MermaidExportRequest {
        let draft = currentDraft ?? DiagramDraft(
            id: UUID(),
            name: "Untitled",
            source: MermaidDocumentSamples.defaultDiagram,
            previewThemeID: MermaidThemePreset.defaultPreset.id,
            exportBackground: .theme,
            isFavorite: false
        )

        return MermaidExportRequest(
            source: draft.source,
            theme: MermaidThemePreset.preset(id: draft.previewThemeID),
            background: draft.exportBackground.resolvedBackground(theme: MermaidThemePreset.preset(id: draft.previewThemeID)),
            padding: 28,
            scale: scale
        )
    }

    private func chooseDestinationURL(for variant: MermaidExportVariant) -> URL? {
        let panel = NSSavePanel()
        panel.title = variant.savePanelTitle
        panel.message = variant.savePanelMessage
        panel.nameFieldStringValue = variant.suggestedFilename
        panel.allowedContentTypes = variant.allowedContentTypes
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private func pngImage(from payload: MermaidPNGExportPayload) throws -> NSImage {
        let pngData = try pngData(from: payload)

        guard let image = NSImage(data: pngData) else {
            throw NSError(
                domain: "Meriq.Export",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not construct an image from the PNG export."]
            )
        }

        return image
    }

    private func pngData(from payload: MermaidPNGExportPayload) throws -> Data {
        let components = payload.dataURL.components(separatedBy: ",")

        guard
            components.count == 2,
            let data = Data(base64Encoded: components[1])
        else {
            throw NSError(
                domain: "Meriq.Export",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not decode the PNG export."]
            )
        }

        return data
    }

    static func sanitizedSource(_ rawSource: String) -> String {
        let trimmed = rawSource.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.hasPrefix("```"), trimmed.hasSuffix("```") else {
            return trimmed
        }

        var lines = trimmed.components(separatedBy: .newlines)

        guard let firstLine = lines.first, firstLine.hasPrefix("```") else {
            return trimmed
        }

        lines.removeFirst()

        if let lastLine = lines.last, lastLine.trimmingCharacters(in: .whitespacesAndNewlines) == "```" {
            lines.removeLast()
        }

        return lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum MermaidDocumentSamples {
    static let defaultDiagram = """
    flowchart LR
        A[Create categories] --> B[Store diagrams locally]
        B --> C{Share output?}
        C -->|Text| D[Copy Mermaid source]
        C -->|Vector| E[Export SVG]
        C -->|Image| F[Export PNG]
    """
}

@MainActor
struct MermaidWebView: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }
}
