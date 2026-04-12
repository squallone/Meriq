//
//  LibraryStore.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
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
