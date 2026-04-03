import AppKit
import Foundation
import SwiftUI

@MainActor
final class LibraryStore: ObservableObject {
    @Published private(set) var categories: [Category] = []
    @Published private(set) var visibleDiagrams: [Diagram] = []
    @Published var sidebarSelection: SidebarSelection = .allDiagrams
    @Published var expandedBrowserSelection: SidebarSelection? = .allDiagrams
    @Published var selectedDiagramID: UUID?
    @Published var searchText = ""
    @Published var isPresentingCategoryEditor = false
    @Published var categoryDraft = CategoryDraft()
    @Published var pendingCategoryDelete: Category?
    @Published private(set) var lastErrorMessage: String?

    private let categoryRepository: CategoryRepository
    private let diagramRepository: DiagramRepository
    private var hasLoaded = false

    init(categoryRepository: CategoryRepository, diagramRepository: DiagramRepository) {
        self.categoryRepository = categoryRepository
        self.diagramRepository = diagramRepository
    }

    var templates: [DiagramTemplate] {
        MermaidStudioTemplates.all
    }

    var isShowingTemplates: Bool {
        sidebarSelection == .templates
    }

    var activeScopeTitle: String {
        switch sidebarSelection {
        case .recents:
            "Recent Diagrams"
        case .favorites:
            "Favorites"
        case .templates:
            "Templates"
        case .allDiagrams:
            "All Diagrams"
        case .uncategorized:
            "Uncategorized"
        case .category(let id):
            categoryName(for: id)
        }
    }

    var activeScopeSubtitle: String {
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Searching inside \(activeScopeTitle.lowercased())"
        }

        switch sidebarSelection {
        case .templates:
            return "Start from a Mermaid scaffold"
        case .allDiagrams:
            return "Browse the full library inline in the sidebar"
        default:
            return "\(visibleDiagrams.count) diagrams available"
        }
    }

    var supportsDiagramReordering: Bool {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }

        switch currentDiagramScope {
        case .category, .uncategorized:
            return true
        case .allDiagrams, .favorites, .recents:
            return false
        }
    }

    var currentDiagramScope: DiagramScope {
        switch sidebarSelection {
        case .recents:
            .recents
        case .favorites:
            .favorites
        case .templates:
            .allDiagrams
        case .allDiagrams:
            .allDiagrams
        case .uncategorized:
            .uncategorized
        case .category(let id):
            .category(id)
        }
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        do {
            try diagramRepository.seedInitialContentIfNeeded()
            try reloadAllData()
            if selectedDiagramID == nil {
                selectedDiagramID = visibleDiagrams.first?.id
            }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func reloadAllData() throws {
        categories = try categoryRepository.fetchCategories()
        try reloadVisibleDiagrams()
        ensureValidSelection()
    }

    func reloadVisibleDiagrams() throws {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            visibleDiagrams = try diagramRepository.searchDiagrams(query: query)
            return
        }

        visibleDiagrams = try diagramRepository.fetchDiagrams(scope: currentDiagramScope)
    }

    func selectSidebar(_ selection: SidebarSelection) {
        if sidebarSelection == selection, browserCapable(selection) {
            expandedBrowserSelection = expandedBrowserSelection == selection ? nil : selection
        } else {
            sidebarSelection = selection
            if browserCapable(selection) {
                expandedBrowserSelection = selection
            }
        }

        do {
            try reloadVisibleDiagrams()
            ensureValidSelection()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func updateSearchText(_ value: String) {
        searchText = value
        if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, browserCapable(sidebarSelection) {
            expandedBrowserSelection = sidebarSelection
        }
        do {
            try reloadVisibleDiagrams()
            ensureValidSelection()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func createDiagram() {
        do {
            let diagram = try diagramRepository.createDiagram(
                in: creationCategoryID,
                name: defaultDiagramName,
                source: MermaidDocumentSamples.defaultDiagram
            )
            try reloadAllData()
            selectedDiagramID = diagram.id
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func createDiagram(from template: DiagramTemplate) {
        do {
            let diagram = try diagramRepository.createDiagram(
                in: creationCategoryID,
                name: template.title,
                source: template.source
            )
            if sidebarSelection == .templates {
                sidebarSelection = .allDiagrams
            }
            try reloadAllData()
            selectedDiagramID = diagram.id
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func deleteSelectedDiagram() {
        guard let selectedDiagramID else { return }
        do {
            try diagramRepository.deleteDiagram(id: selectedDiagramID)
            try reloadAllData()
            self.selectedDiagramID = visibleDiagrams.first?.id
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(_ diagram: Diagram) {
        do {
            try diagramRepository.setFavorite(id: diagram.id, isFavorite: !diagram.isFavorite)
            try reloadAllData()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func moveDiagram(_ diagram: Diagram, to categoryID: UUID?) {
        do {
            try diagramRepository.updateDiagramMetadata(id: diagram.id, name: diagram.name, categoryID: categoryID)
            try reloadAllData()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func moveCategories(fromOffsets source: IndexSet, toOffset destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        persistCategoryOrder(reordered.map(\.id))
    }

    func moveDiagrams(fromOffsets source: IndexSet, toOffset destination: Int) {
        guard supportsDiagramReordering else { return }
        var reordered = visibleDiagrams
        reordered.move(fromOffsets: source, toOffset: destination)
        let categoryID = diagramReorderCategoryID

        do {
            try diagramRepository.reorderDiagrams(in: categoryID, idsInOrder: reordered.map(\.id))
            try reloadVisibleDiagrams()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func presentNewCategorySheet() {
        categoryDraft = CategoryDraft()
        isPresentingCategoryEditor = true
    }

    func presentEditCategorySheet(_ category: Category) {
        categoryDraft = CategoryDraft(category: category)
        isPresentingCategoryEditor = true
    }

    func saveCategoryDraft() {
        do {
            if let id = categoryDraft.id {
                try categoryRepository.updateCategory(
                    id: id,
                    name: categoryDraft.name,
                    iconSystemName: categoryDraft.iconSystemName,
                    colorHex: categoryDraft.colorHex
                )
            } else {
                _ = try categoryRepository.createCategory(
                    name: categoryDraft.name,
                    iconSystemName: categoryDraft.iconSystemName,
                    colorHex: categoryDraft.colorHex
                )
            }

            try reloadAllData()
            isPresentingCategoryEditor = false
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func confirmDeleteCategory(_ category: Category) {
        pendingCategoryDelete = category
    }

    func deletePendingCategory() {
        guard let category = pendingCategoryDelete else { return }

        do {
            try categoryRepository.deleteCategory(id: category.id, moveDiagramsTo: nil)
            if sidebarSelection == .category(category.id) {
                sidebarSelection = .uncategorized
            }
            pendingCategoryDelete = nil
            try reloadAllData()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    func clearCategoryDeleteConfirmation() {
        pendingCategoryDelete = nil
    }

    func categoryName(for id: UUID?) -> String {
        guard let id else { return "Uncategorized" }
        return categories.first(where: { $0.id == id })?.name ?? "Unknown Category"
    }

    func category(for id: UUID) -> Category? {
        categories.first(where: { $0.id == id })
    }

    func browserCapable(_ selection: SidebarSelection) -> Bool {
        switch selection {
        case .templates:
            return false
        case .recents, .favorites, .allDiagrams, .uncategorized, .category:
            return true
        }
    }

    func isInlineBrowserExpanded(for selection: SidebarSelection) -> Bool {
        expandedBrowserSelection == selection
    }

    func sidebarDiagramSections(for selection: SidebarSelection) -> [SidebarDiagramSection] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return groupedSections(from: visibleDiagrams, includeEmptyCategories: false)
        }

        switch selection {
        case .allDiagrams:
            return groupedSections(from: visibleDiagrams, includeEmptyCategories: false)
        case .category(let id):
            let category = category(for: id)
            return [
                SidebarDiagramSection(
                    id: "category-\(id.uuidString)",
                    title: category?.name ?? "Category",
                    symbolName: category?.iconSystemName ?? "folder",
                    tintHex: category?.colorHex,
                    diagrams: visibleDiagrams
                )
            ]
        case .uncategorized:
            return [
                SidebarDiagramSection(
                    id: "uncategorized",
                    title: "Uncategorized",
                    symbolName: "tray",
                    tintHex: nil,
                    diagrams: visibleDiagrams
                )
            ]
        case .favorites:
            return [
                SidebarDiagramSection(
                    id: "favorites",
                    title: "Favorites",
                    symbolName: "star",
                    tintHex: "#F7D154",
                    diagrams: visibleDiagrams
                )
            ]
        case .recents:
            return [
                SidebarDiagramSection(
                    id: "recents",
                    title: "Recents",
                    symbolName: "clock.arrow.circlepath",
                    tintHex: "#5AB7FF",
                    diagrams: visibleDiagrams
                )
            ]
        case .templates:
            return []
        }
    }

    func refreshAfterDiagramOpen() {
        do {
            try reloadVisibleDiagrams()
            categories = try categoryRepository.fetchCategories()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private var creationCategoryID: UUID? {
        switch sidebarSelection {
        case .category(let id):
            id
        case .uncategorized:
            nil
        default:
            selectedDiagram.flatMap(\.categoryID)
        }
    }

    private var selectedDiagram: Diagram? {
        visibleDiagrams.first(where: { $0.id == selectedDiagramID })
    }

    private var defaultDiagramName: String {
        "New Diagram"
    }

    private var diagramReorderCategoryID: UUID? {
        switch currentDiagramScope {
        case .category(let id):
            id
        case .uncategorized:
            nil
        case .allDiagrams, .favorites, .recents:
            nil
        }
    }

    private func persistCategoryOrder(_ idsInOrder: [UUID]) {
        do {
            try categoryRepository.reorderCategories(idsInOrder)
            try reloadAllData()
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func ensureValidSelection() {
        if visibleDiagrams.contains(where: { $0.id == selectedDiagramID }) {
            return
        }
        selectedDiagramID = visibleDiagrams.first?.id
    }

    private func groupedSections(from diagrams: [Diagram], includeEmptyCategories: Bool) -> [SidebarDiagramSection] {
        let groupedByCategory = Dictionary(grouping: diagrams, by: \.categoryID)
        var sections: [SidebarDiagramSection] = categories.map { category in
            SidebarDiagramSection(
                id: "category-\(category.id.uuidString)",
                title: category.name,
                symbolName: category.iconSystemName,
                tintHex: category.colorHex,
                diagrams: groupedByCategory[category.id, default: []]
                    .sorted { lhs, rhs in
                        if lhs.sortOrder == rhs.sortOrder {
                            return lhs.updatedAt > rhs.updatedAt
                        }
                        return lhs.sortOrder < rhs.sortOrder
                    }
            )
        }

        let uncategorized = groupedByCategory[nil, default: []]
        if includeEmptyCategories || !uncategorized.isEmpty {
            sections.append(
                SidebarDiagramSection(
                    id: "uncategorized",
                    title: "Uncategorized",
                    symbolName: "tray",
                    tintHex: nil,
                    diagrams: uncategorized
                        .sorted { lhs, rhs in
                            if lhs.sortOrder == rhs.sortOrder {
                                return lhs.updatedAt > rhs.updatedAt
                            }
                            return lhs.sortOrder < rhs.sortOrder
                        }
                )
            )
        }

        return sections.filter { includeEmptyCategories || !$0.diagrams.isEmpty }
    }
}

struct CategoryDraft {
    var id: UUID?
    var name = ""
    var iconSystemName = MermaidStudioSymbols.categories.first ?? "folder"
    var colorHex = "#53C3B0"

    init() {
    }

    init(category: Category) {
        self.id = category.id
        self.name = category.name
        self.iconSystemName = category.iconSystemName
        self.colorHex = category.colorHex ?? "#53C3B0"
    }
}

@MainActor
final class EditorStore: ObservableObject {
    @Published private(set) var draft: DiagramDraft?
    @Published var exportConfiguration = MermaidExportConfiguration()
    @Published private(set) var previewZoomState = DiagramPreviewZoomState()
    @Published private(set) var previewToolMode: PreviewToolMode = .none
    @Published var workspaceMode: WorkspaceMode = .split
    @Published var isDocumentPanelCollapsed = false
    @Published private(set) var selectedCategoryID: UUID?
    @Published private(set) var statusMessage = "Create a diagram or choose one from the library."
    @Published private(set) var isRendererError = false
    @Published private(set) var documentPanelHeight: CGFloat = 248

    let renderer = MermaidRenderer()
    var onPersist: (() -> Void)?

    private let diagramRepository: DiagramRepository
    private let sourceEditingEngine = MermaidSourceEditingEngine()
    private var autosaveTask: Task<Void, Never>?
    private var lastExpandedDocumentPanelHeight: CGFloat = 248
    private var lastPreviewToolToggleAt: Date = .distantPast
    private let previewToolToggleDebounceInterval: TimeInterval = 0.28
    private var isKeyboardZoomSessionActive = false
    private var previewToolModeBeforeKeyboardZoomSession: PreviewToolMode = .none

    init(diagramRepository: DiagramRepository) {
        self.diagramRepository = diagramRepository
        statusMessage = renderer.statusMessage
        isRendererError = renderer.isError
        renderer.statusObserver = { [weak self] message, isError in
            self?.statusMessage = message
            self?.isRendererError = isError
        }
        renderer.previewEditHandler = { [weak self] request in
            self?.applyPreviewEdit(request)
        }
        renderer.setPreviewZoom(previewZoomState.scale, animated: false)
    }

    func handleSelectionChange(_ diagramID: UUID?) {
        flushAutosaveIfNeeded()

        guard let diagramID else {
            draft = nil
            previewToolMode = .none
            renderer.clear()
            statusMessage = renderer.statusMessage
            isRendererError = renderer.isError
            return
        }

        do {
            guard let diagram = try diagramRepository.fetchDiagram(id: diagramID) else {
                draft = nil
                return
            }

            selectedCategoryID = diagram.categoryID
            draft = DiagramDraft(diagram: diagram)
            renderer.apply(
                draft: DiagramDraft(diagram: diagram),
                editableTokens: editableTokens(for: DiagramDraft(diagram: diagram))
            )
            try diagramRepository.markOpened(id: diagramID, at: .now)
            onPersist?()
            statusMessage = renderer.statusMessage
            isRendererError = renderer.isError
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func updateName(_ name: String) {
        guard var draft else { return }
        draft.name = name
        self.draft = draft
        scheduleAutosave()
    }

    func updateSource(_ source: String) {
        guard var draft else { return }
        draft.source = source
        self.draft = draft
        renderer.apply(
            draft: draft,
            shouldRender: false,
            editableTokens: editableTokens(for: draft)
        )
        scheduleAutosave()
    }

    func updateTheme(_ themeID: String) {
        guard var draft else { return }
        draft.previewThemeID = themeID
        self.draft = draft
        renderer.apply(draft: draft, editableTokens: editableTokens(for: draft))
        scheduleAutosave()
    }

    func updateExportMode(_ mode: MermaidExportBackgroundStyle.Mode) {
        guard var draft else { return }
        draft.exportBackground.mode = mode
        self.draft = draft
        renderer.apply(
            draft: draft,
            shouldRender: false,
            editableTokens: editableTokens(for: draft)
        )
        scheduleAutosave()
    }

    func updateExportColor(_ color: Color) {
        guard var draft else { return }
        draft.exportBackground.customColorHex = color.hexRGBString
        self.draft = draft
        renderer.apply(
            draft: draft,
            shouldRender: false,
            editableTokens: editableTokens(for: draft)
        )
        scheduleAutosave()
    }

    func toggleFavorite() {
        guard var draft else { return }
        draft.isFavorite.toggle()
        self.draft = draft
        scheduleAutosave()
    }

    func updateCategoryID(_ categoryID: UUID?) {
        selectedCategoryID = categoryID
        guard let draft else { return }

        do {
            try diagramRepository.updateDiagramMetadata(id: draft.id, name: draft.name, categoryID: categoryID)
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func pasteSourceFromClipboard() {
        guard let clipboardText = NSPasteboard.general.string(forType: .string) else {
            statusMessage = "Clipboard does not contain plain text."
            renderer.setStatus(statusMessage, isError: true)
            return
        }
        updateSource(MermaidRenderer.sanitizedSource(clipboardText))
    }

    func copySourceToClipboard() {
        guard let source = draft?.source else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(source, forType: .string)
        statusMessage = "Copied Mermaid source to the clipboard."
        renderer.setStatus(statusMessage, isError: false)
    }

    func renderPreview() {
        renderer.renderPreview()
        statusMessage = renderer.statusMessage
        isRendererError = renderer.isError
    }

    func activatePreviewTool(_ mode: PreviewToolMode) {
        switch mode {
        case .none:
            cancelPreviewTool()
        case .zoomIn:
            guard previewZoomState.canZoomIn else { return }
            setActivePreviewTool(.zoomIn)
        case .zoomOut:
            guard previewZoomState.canZoomOut else { return }
            setActivePreviewTool(.zoomOut)
        }
    }

    func zoomInPreviewImmediately() {
        guard previewZoomState.canZoomIn else { return }
        applyPreviewZoom(previewZoomState.zoomingIn())
        setPreviewInteractionStatus("Zoomed to \(previewZoomState.percentageLabel).")
    }

    func zoomOutPreviewImmediately() {
        guard previewZoomState.canZoomOut else { return }
        applyPreviewZoom(previewZoomState.zoomingOut())
        setPreviewInteractionStatus("Zoomed to \(previewZoomState.percentageLabel).")
    }

    func beginKeyboardZoomSession(optionPressed: Bool) {
        let requestedMode: PreviewToolMode = optionPressed ? .zoomOut : .zoomIn
        guard canActivatePreviewTool(requestedMode) else { return }

        if !isKeyboardZoomSessionActive {
            isKeyboardZoomSessionActive = true
            previewToolModeBeforeKeyboardZoomSession = previewToolMode
        }

        setPreviewToolForKeyboardSession(requestedMode)
    }

    func updateKeyboardZoomSession(optionPressed: Bool) {
        guard isKeyboardZoomSessionActive else { return }
        let requestedMode: PreviewToolMode = optionPressed ? .zoomOut : .zoomIn

        if canActivatePreviewTool(requestedMode) {
            setPreviewToolForKeyboardSession(requestedMode)
        } else {
            setPreviewInteractionStatus(requestedMode == .zoomOut
                ? "Already at minimum zoom."
                : "Already at maximum zoom.")
        }
    }

    func endKeyboardZoomSession() {
        guard isKeyboardZoomSessionActive else { return }
        isKeyboardZoomSessionActive = false

        let previousMode = previewToolModeBeforeKeyboardZoomSession
        previewToolModeBeforeKeyboardZoomSession = .none

        if previousMode == .none {
            previewToolMode = .none
            syncStatusFromRenderer()
        } else if canActivatePreviewTool(previousMode) {
            previewToolMode = previousMode
            setPreviewInteractionStatus(previousMode.instruction)
        } else {
            previewToolMode = .none
            syncStatusFromRenderer()
        }
    }

    func resetPreviewZoom() {
        previewToolMode = .none
        applyPreviewZoom(previewZoomState.resetting())
    }

    func cancelPreviewTool() {
        guard previewToolMode.isActive || isKeyboardZoomSessionActive else { return }
        isKeyboardZoomSessionActive = false
        previewToolModeBeforeKeyboardZoomSession = .none
        previewToolMode = .none
        lastPreviewToolToggleAt = .now
        syncStatusFromRenderer()
    }

    func performPreviewToolClick() {
        switch previewToolMode {
        case .none:
            return
        case .zoomIn:
            let wasAtLimit = !previewZoomState.canZoomIn
            let updatedState = previewZoomState.zoomingIn()
            applyPreviewZoom(updatedState)
            if wasAtLimit {
                setPreviewInteractionStatus("Already at maximum zoom. Click elsewhere, or press Esc to leave the zoom tool.")
            } else {
                setPreviewInteractionStatus("Zoomed to \(updatedState.percentageLabel). Click again to keep zooming in, or press Esc to leave the tool.")
            }
        case .zoomOut:
            let wasAtLimit = !previewZoomState.canZoomOut
            let updatedState = previewZoomState.zoomingOut()
            applyPreviewZoom(updatedState)
            if wasAtLimit {
                setPreviewInteractionStatus("Already at minimum zoom. Click elsewhere, or press Esc to leave the zoom tool.")
            } else {
                setPreviewInteractionStatus("Zoomed to \(updatedState.percentageLabel). Click again to keep zooming out, or press Esc to leave the tool.")
            }
        }
    }

    func toggleDocumentPanel() {
        if isDocumentPanelCollapsed {
            isDocumentPanelCollapsed = false
            documentPanelHeight = lastExpandedDocumentPanelHeight
        } else {
            lastExpandedDocumentPanelHeight = documentPanelHeight
            isDocumentPanelCollapsed = true
        }
    }

    func setDocumentPanelHeight(_ newHeight: CGFloat, maxHeight: CGFloat) {
        let clamped = min(max(newHeight, 160), maxHeight)
        documentPanelHeight = clamped
        lastExpandedDocumentPanelHeight = clamped
        if isDocumentPanelCollapsed {
            isDocumentPanelCollapsed = false
        }
    }

    func flushAutosaveIfNeeded() {
        autosaveTask?.cancel()
        autosaveTask = nil
        persistDraft()
    }

    private func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(550))
            self?.persistDraft()
        }
    }

    private func applyPreviewEdit(_ request: MermaidPreviewEditRequest) {
        guard var draft else { return }

        do {
            let result = try sourceEditingEngine.applyPreviewEdit(request, to: draft.source)
            draft.source = result.updatedSource
            self.draft = draft
            renderer.apply(draft: draft, editableTokens: editableTokens(for: draft))
            scheduleAutosave()
            let scopeLabel = result.editedToken.kind == .nodeLabel ? "node" : "edge"
            statusMessage = "Updated \(scopeLabel) text in the Mermaid source from the preview."
            isRendererError = false
        } catch {
            statusMessage = error.localizedDescription
            renderer.setStatus(statusMessage, isError: true)
        }
    }

    private func persistDraft() {
        guard let draft else { return }

        do {
            try diagramRepository.updateDiagramContent(id: draft.id, draft: draft)
            if let categoryID = selectedCategoryID {
                try diagramRepository.updateDiagramMetadata(id: draft.id, name: draft.name, categoryID: categoryID)
            } else {
                try diagramRepository.updateDiagramMetadata(id: draft.id, name: draft.name, categoryID: nil)
            }
            renderer.apply(draft: draft, editableTokens: editableTokens(for: draft))
            onPersist?()
            statusMessage = renderer.statusMessage
            isRendererError = renderer.isError
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func editableTokens(for draft: DiagramDraft) -> [MermaidEditableToken] {
        sourceEditingEngine.editableTokens(in: draft.source)
    }

    private func applyPreviewZoom(_ state: DiagramPreviewZoomState) {
        guard state != previewZoomState else { return }
        previewZoomState = state
        renderer.setPreviewZoom(state.scale)
    }

    private func canActivatePreviewTool(_ mode: PreviewToolMode) -> Bool {
        switch mode {
        case .none:
            true
        case .zoomIn:
            previewZoomState.canZoomIn
        case .zoomOut:
            previewZoomState.canZoomOut
        }
    }

    private func setPreviewToolForKeyboardSession(_ mode: PreviewToolMode) {
        guard previewToolMode != mode else { return }
        previewToolMode = mode
        setPreviewInteractionStatus(mode.instruction)
    }

    private func setActivePreviewTool(_ mode: PreviewToolMode) {
        let now = Date()

        if previewToolMode == mode {
            guard now.timeIntervalSince(lastPreviewToolToggleAt) >= previewToolToggleDebounceInterval else {
                return
            }

            previewToolMode = .none
            lastPreviewToolToggleAt = now
            syncStatusFromRenderer()
            return
        }

        previewToolMode = mode
        lastPreviewToolToggleAt = now
        setPreviewInteractionStatus(mode.instruction)
    }

    private func setPreviewInteractionStatus(_ message: String) {
        statusMessage = message
        isRendererError = false
    }

    private func syncStatusFromRenderer() {
        statusMessage = renderer.statusMessage
        isRendererError = renderer.isError
    }
}
