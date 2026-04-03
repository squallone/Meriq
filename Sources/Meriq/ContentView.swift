import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RootStudioView()
            .background(
                WindowChromeConfigurator()
                    .frame(width: 0, height: 0)
            )
            .task {
                libraryStore.loadIfNeeded()
                editorStore.handleSelectionChange(libraryStore.selectedDiagramID)
            }
            .onChange(of: libraryStore.selectedDiagramID) { _, newValue in
                editorStore.handleSelectionChange(newValue)
                libraryStore.refreshAfterDiagramOpen()
            }
            .onChange(of: libraryStore.sidebarSelection) { _, _ in
                editorStore.flushAutosaveIfNeeded()
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue != .active else { return }
                editorStore.flushAutosaveIfNeeded()
            }
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowChromeView {
        WindowChromeView()
    }

    func updateNSView(_ nsView: WindowChromeView, context: Context) {
        nsView.applyIfNeeded()
    }
}

@MainActor
private final class WindowChromeView: NSView {
    private var didApplyInitialChrome = false

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        applyIfNeeded()
    }

    func applyIfNeeded() {
        guard let window else { return }

        let titlebarColor = NSColor(
            calibratedRed: 0.09,
            green: 0.09,
            blue: 0.12,
            alpha: 1
        )

        let contentBackground = NSColor(
            calibratedRed: 0.05,
            green: 0.06,
            blue: 0.08,
            alpha: 1
        )

        if !didApplyInitialChrome {
            window.toolbarStyle = .unifiedCompact
            window.titlebarAppearsTransparent = true
            window.isOpaque = true
            window.titleVisibility = .visible
            window.backgroundColor = contentBackground
            didApplyInitialChrome = true
        }

        if let toolbarView = window.contentView?.superview?.subviews.first(where: { NSStringFromClass(type(of: $0)).contains("NSTitlebar") }) {
            toolbarView.wantsLayer = true
            toolbarView.layer?.backgroundColor = titlebarColor.cgColor
        }

        if let toolbar = window.toolbar {
            toolbar.showsBaselineSeparator = false
        }
    }
}
