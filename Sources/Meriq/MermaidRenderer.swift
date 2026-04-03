import AppKit
import SwiftUI
import WebKit

@MainActor
final class MermaidRenderer: ObservableObject {
    @Published var source = MermaidDocumentSamples.defaultDiagram
    @Published private(set) var statusMessage = "Paste Mermaid syntax, choose a theme, and click Render."
    @Published private(set) var isError = false
    @Published private(set) var selectedThemeID = MermaidThemePreset.defaultPreset.id
    @Published private(set) var exportOptions = MermaidExportOptions()

    let webView: WKWebView

    private let previewEngine: MermaidRenderEngine
    private let exportEngine: MermaidRenderEngine

    init() {
        let previewEngine = MermaidRenderEngine()

        self.previewEngine = previewEngine
        self.exportEngine = MermaidRenderEngine()
        self.webView = previewEngine.webView

        previewEngine.statusHandler = { [weak self] message, isError in
            self?.setStatus(message, isError: isError)
        }

        renderPreview()
    }

    var availableThemes: [MermaidThemePreset] {
        MermaidThemePreset.all
    }

    var currentTheme: MermaidThemePreset {
        MermaidThemePreset.preset(id: selectedThemeID)
    }

    var exportBackgroundMode: MermaidExportBackgroundStyle.Mode {
        exportOptions.background.mode
    }

    var exportBackgroundColor: Color {
        Color(hexString: exportOptions.background.customColorHex)
    }

    func loadSample() {
        source = MermaidDocumentSamples.defaultDiagram
        renderPreview()
    }

    func updateSourceFromPasteboard(_ rawSource: String) {
        source = sanitizedSource(rawSource)
        renderPreview()
    }

    func selectTheme(_ themeID: String) {
        guard selectedThemeID != themeID else {
            return
        }

        selectedThemeID = themeID
        renderPreview()
    }

    func selectExportBackgroundMode(_ mode: MermaidExportBackgroundStyle.Mode) {
        exportOptions.background.mode = mode
        setStatus(exportDescription(for: mode), isError: false)
    }

    func selectExportBackgroundColor(_ color: Color) {
        exportOptions.background.customColorHex = color.hexRGBString
        setStatus("Updated the custom export background color.", isError: false)
    }

    func renderPreview() {
        setStatus("Rendering diagram…", isError: false)

        let preparedSource = prepareRenderableSource()

        let request = MermaidPreviewRequest(
            source: preparedSource,
            theme: currentTheme,
            padding: 18
        )

        previewEngine.renderPreview(request) { [weak self] result in
            guard case .failure(let error) = result else {
                return
            }

            self?.setStatus("Could not render the diagram: \(error.localizedDescription)", isError: true)
        }
    }

    func copySVGToClipboard() {
        setStatus("Preparing SVG export…", isError: false)

        exportEngine.exportSVG(buildExportRequest()) { [weak self] result in
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

    func copyImageToClipboard() {
        setStatus("Preparing PNG export…", isError: false)

        exportEngine.exportPNG(buildExportRequest()) { [weak self] result in
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

    func exportSVGToFile() {
        guard let destinationURL = chooseDestinationURL(for: .svg) else {
            setStatus("SVG export cancelled.", isError: false)
            return
        }

        setStatus("Preparing SVG export…", isError: false)

        exportEngine.exportSVG(buildExportRequest()) { [weak self] result in
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

    func exportPNGToFile() {
        guard let destinationURL = chooseDestinationURL(for: .png) else {
            setStatus("PNG export cancelled.", isError: false)
            return
        }

        setStatus("Preparing PNG export…", isError: false)

        exportEngine.exportPNG(buildExportRequest()) { [weak self] result in
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
    }

    private func buildExportRequest() -> MermaidExportRequest {
        let preparedSource = prepareRenderableSource()

        return MermaidExportRequest(
            source: preparedSource,
            theme: currentTheme,
            background: exportOptions.background.resolvedBackground(theme: currentTheme),
            padding: exportOptions.padding,
            scale: exportOptions.scale
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

    private func exportDescription(for mode: MermaidExportBackgroundStyle.Mode) -> String {
        switch mode {
        case .theme:
            "Exports will use the selected theme background."
        case .transparent:
            "Exports will use a transparent background."
        case .custom:
            "Exports will use the selected custom background color."
        }
    }

    private func prepareRenderableSource() -> String {
        let cleaned = sanitizedSource(source)

        if cleaned != source {
            source = cleaned
        }

        return cleaned
    }

    private func sanitizedSource(_ rawSource: String) -> String {
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

private enum MermaidDocumentSamples {
    static let defaultDiagram = """
    flowchart LR
        A[Paste Mermaid syntax] --> B(Render in the app)
        B --> C{Need to share it?}
        C -->|Text| D[Copy source]
        C -->|Vector| E[Copy SVG]
        C -->|Image| F[Copy rendered image]
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
