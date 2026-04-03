import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var renderer = MermaidRenderer()

    var body: some View {
        VStack(spacing: 14) {
            header
            configurationBar
            HSplitView {
                editorPane
                previewPane
            }
            statusBar
        }
        .padding(16)
        .frame(minWidth: 1120, minHeight: 760)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meriq")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                Text("Preview and export diagrams with reusable theme and background options.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Load Sample") {
                renderer.loadSample()
            }
            Button("Paste Source") {
                pasteSourceFromClipboard()
            }
            Button("Render") {
                renderer.renderPreview()
            }
            .buttonStyle(.borderedProminent)
            Menu("Copy") {
                Button("Mermaid Source") {
                    copySourceToClipboard()
                }
                Button("SVG Markup") {
                    renderer.copySVGToClipboard()
                }
                Button("Rendered PNG") {
                    renderer.copyImageToClipboard()
                }
            }
            Menu("Export") {
                Button("Mermaid Source (.mmd)") {
                    exportSourceToFile()
                }
                Button("SVG (.svg)") {
                    renderer.exportSVGToFile()
                }
                Button("PNG (.png)") {
                    renderer.exportPNGToFile()
                }
            }
        }
    }

    private var configurationBar: some View {
        HStack(spacing: 18) {
            HStack(spacing: 8) {
                Text("Theme")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Picker("Theme", selection: themeSelection) {
                    ForEach(renderer.availableThemes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .frame(width: 150)
                .pickerStyle(.menu)
            }

            HStack(spacing: 8) {
                Text("Export Background")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Picker("Export Background", selection: exportBackgroundModeSelection) {
                    ForEach(MermaidExportBackgroundStyle.Mode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .frame(width: 160)
                .pickerStyle(.menu)
            }

            if renderer.exportBackgroundMode == .custom {
                HStack(spacing: 8) {
                    ColorPicker("Custom Background", selection: exportBackgroundColorSelection, supportsOpacity: false)
                        .labelsHidden()
                    Text(renderer.exportOptions.background.customColorHex)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("Preview uses the selected theme. SVG and PNG export share one reusable export configuration.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 2)
    }

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mermaid")
                .font(.headline)
            TextEditor(text: $renderer.source)
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(minWidth: 440)
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview")
                .font(.headline)
            MermaidWebView(webView: renderer.webView)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
        }
        .frame(minWidth: 440)
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(renderer.isError ? Color.red : Color.green)
                .frame(width: 8, height: 8)
            Text(renderer.statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(renderer.isError ? Color.red : Color.secondary)
            Spacer()
            Text("Tip: render the current source after edits; theme changes update the preview immediately.")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private var themeSelection: Binding<String> {
        Binding(
            get: { renderer.selectedThemeID },
            set: { renderer.selectTheme($0) }
        )
    }

    private var exportBackgroundModeSelection: Binding<MermaidExportBackgroundStyle.Mode> {
        Binding(
            get: { renderer.exportBackgroundMode },
            set: { renderer.selectExportBackgroundMode($0) }
        )
    }

    private var exportBackgroundColorSelection: Binding<Color> {
        Binding(
            get: { renderer.exportBackgroundColor },
            set: { renderer.selectExportBackgroundColor($0) }
        )
    }

    private func pasteSourceFromClipboard() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string) else {
            renderer.setStatus("Clipboard does not contain plain text.", isError: true)
            return
        }

        renderer.updateSourceFromPasteboard(clipboardText)
    }

    private func copySourceToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(renderer.source, forType: .string)
        renderer.setStatus("Copied Mermaid source to the clipboard.", isError: false)
    }

    private func exportSourceToFile() {
        let panel = NSSavePanel()
        panel.title = "Export Mermaid Source"
        panel.message = "Choose where to save the Mermaid text."
        panel.nameFieldStringValue = "diagram.mmd"
        panel.allowedContentTypes = [UTType(filenameExtension: "mmd") ?? .plainText]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let destinationURL = panel.url else {
            renderer.setStatus("Mermaid source export cancelled.", isError: false)
            return
        }

        do {
            try renderer.source.write(to: destinationURL, atomically: true, encoding: .utf8)
            renderer.setStatus("Saved Mermaid source to \(destinationURL.lastPathComponent).", isError: false)
        } catch {
            renderer.setStatus("Could not save the Mermaid source: \(error.localizedDescription)", isError: true)
        }
    }
}
