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
        .defaultSize(width: 1460, height: 900)
    }
}
