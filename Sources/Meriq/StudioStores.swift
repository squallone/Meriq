import AppKit
import Foundation
import SwiftUI


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
