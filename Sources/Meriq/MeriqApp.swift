import SwiftUI
import SwiftData

@main
struct MeriqApp: App {
    private let container: ModelContainer
    @StateObject private var libraryStore: LibraryStore
    @StateObject private var editorStore: EditorStore

    init() {
        let schema = Schema([
            CategoryEntity.self,
            DiagramEntity.self
        ])
        let configuration = ModelConfiguration("MeriqLibrary")
        let container = try! ModelContainer(for: schema, configurations: configuration)
        self.container = container

        let categoryRepository = SwiftDataCategoryRepository(context: container.mainContext)
        let diagramRepository = SwiftDataDiagramRepository(context: container.mainContext)
        let libraryStore = LibraryStore(
            categoryRepository: categoryRepository,
            diagramRepository: diagramRepository
        )
        let editorStore = EditorStore(diagramRepository: diagramRepository)
        editorStore.onPersist = {
            libraryStore.refreshAfterDiagramOpen()
        }

        _libraryStore = StateObject(
            wrappedValue: libraryStore
        )
        _editorStore = StateObject(
            wrappedValue: editorStore
        )
    }

    var body: some Scene {
        WindowGroup("Meriq") {
            ContentView()
                .environmentObject(libraryStore)
                .environmentObject(editorStore)
                .modelContainer(container)
                .preferredColorScheme(.dark)
        }
        .commands {
            PreviewZoomCommands(editorStore: editorStore)
        }
        .defaultSize(width: 1460, height: 900)
    }
}

struct PreviewZoomCommands: Commands {
    @ObservedObject var editorStore: EditorStore

    var body: some Commands {
        CommandMenu("Preview") {
            Button("Activate Zoom In Tool") {
                editorStore.activatePreviewTool(.zoomIn)
            }
            .disabled(!editorStore.previewZoomState.canZoomIn)

            Button("Activate Zoom Out Tool") {
                editorStore.activatePreviewTool(.zoomOut)
            }
            .disabled(!editorStore.previewZoomState.canZoomOut)

            Button("Cancel Preview Tool") {
                editorStore.cancelPreviewTool()
            }
            .disabled(!editorStore.previewToolMode.isActive)

            Divider()

            Button("Reset Zoom") {
                editorStore.resetPreviewZoom()
            }
            .disabled(editorStore.previewZoomState.scale == DiagramPreviewZoomState.defaultScale)
        }
    }
}
