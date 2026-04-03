import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        RootStudioView()
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
