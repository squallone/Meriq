import Foundation
import SwiftData

@MainActor
protocol CategoryRepository {
    func fetchCategories() throws -> [Category]
    func createCategory(name: String, iconSystemName: String, colorHex: String?) throws -> Category
    func updateCategory(id: UUID, name: String, iconSystemName: String, colorHex: String?) throws
    func deleteCategory(id: UUID, moveDiagramsTo targetCategoryID: UUID?) throws
    func reorderCategories(_ idsInOrder: [UUID]) throws
}

@MainActor
protocol DiagramRepository {
    func fetchDiagrams(scope: DiagramScope) throws -> [Diagram]
    func fetchDiagram(id: UUID) throws -> Diagram?
    func createDiagram(in categoryID: UUID?, name: String, source: String) throws -> Diagram
    func updateDiagramMetadata(id: UUID, name: String, categoryID: UUID?) throws
    func updateDiagramContent(id: UUID, draft: DiagramDraft) throws
    func setFavorite(id: UUID, isFavorite: Bool) throws
    func markOpened(id: UUID, at: Date) throws
    func deleteDiagram(id: UUID) throws
    func reorderDiagrams(in categoryID: UUID?, idsInOrder: [UUID]) throws
    func searchDiagrams(query: String) throws -> [Diagram]
    func seedInitialContentIfNeeded() throws
}

@MainActor
final class SwiftDataCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(
            sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.name)
            ]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    func createCategory(name: String, iconSystemName: String, colorHex: String?) throws -> Category {
        let entity = CategoryEntity(
            name: normalizedName(name, fallback: "Untitled Category"),
            iconSystemName: iconSystemName,
            colorHex: colorHex,
            sortOrder: nextCategorySortOrder()
        )
        context.insert(entity)
        try context.save()
        return entity.toDomain()
    }

    func updateCategory(id: UUID, name: String, iconSystemName: String, colorHex: String?) throws {
        guard let entity = try fetchCategoryEntity(id: id) else { return }
        entity.name = normalizedName(name, fallback: entity.name)
        entity.iconSystemName = iconSystemName
        entity.colorHex = colorHex
        entity.updatedAt = .now
        try context.save()
    }

    func deleteCategory(id: UUID, moveDiagramsTo targetCategoryID: UUID?) throws {
        guard let category = try fetchCategoryEntity(id: id) else { return }
        let targetCategory = try targetCategoryID.flatMap { try fetchCategoryEntity(id: $0) }

        for diagram in category.diagrams {
            diagram.category = targetCategory
            diagram.updatedAt = .now
        }

        context.delete(category)
        try context.save()
    }

    func reorderCategories(_ idsInOrder: [UUID]) throws {
        guard !idsInOrder.isEmpty else { return }
        let categories = try context.fetch(FetchDescriptor<CategoryEntity>())
        let positions = Dictionary(uniqueKeysWithValues: idsInOrder.enumerated().map { ($0.element, $0.offset) })

        for category in categories {
            guard let sortOrder = positions[category.id] else { continue }
            category.sortOrder = sortOrder
            category.updatedAt = .now
        }

        try context.save()
    }

    private func fetchCategoryEntity(id: UUID) throws -> CategoryEntity? {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    private func nextCategorySortOrder() -> Int {
        ((try? fetchCategories().map(\.sortOrder).max()) ?? -1) + 1
    }

    private func normalizedName(_ rawName: String, fallback: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

@MainActor
final class SwiftDataDiagramRepository: DiagramRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchDiagrams(scope: DiagramScope) throws -> [Diagram] {
        let entities = try fetchDiagramEntities()

        let filtered = entities.filter { entity in
            switch scope {
            case .allDiagrams:
                true
            case .favorites:
                entity.isFavorite
            case .recents:
                entity.lastOpenedAt != nil
            case .uncategorized:
                entity.category == nil
            case .category(let categoryID):
                entity.category?.id == categoryID
            }
        }

        let sorted: [DiagramEntity]
        switch scope {
        case .recents:
            sorted = filtered.sorted {
                ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast)
            }
        default:
            sorted = filtered.sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }
        }

        return sorted.map { $0.toDomain() }
    }

    func fetchDiagram(id: UUID) throws -> Diagram? {
        try fetchDiagramEntity(id: id)?.toDomain()
    }

    func createDiagram(in categoryID: UUID?, name: String, source: String) throws -> Diagram {
        let category = try categoryID.flatMap { try fetchCategoryEntity(id: $0) }
        let entity = DiagramEntity(
            name: normalizedName(name, fallback: "Untitled Diagram"),
            source: source.trimmingCharacters(in: .whitespacesAndNewlines),
            sortOrder: nextDiagramSortOrder(in: categoryID),
            category: category
        )
        entity.lastOpenedAt = .now
        context.insert(entity)
        try context.save()
        return entity.toDomain()
    }

    func updateDiagramMetadata(id: UUID, name: String, categoryID: UUID?) throws {
        guard let entity = try fetchDiagramEntity(id: id) else { return }
        let newCategory = try categoryID.flatMap { try fetchCategoryEntity(id: $0) }
        let previousCategoryID = entity.category?.id

        entity.name = normalizedName(name, fallback: entity.name)
        entity.category = newCategory
        entity.updatedAt = .now

        if previousCategoryID != categoryID {
            entity.sortOrder = nextDiagramSortOrder(in: categoryID)
        }

        try context.save()
    }

    func updateDiagramContent(id: UUID, draft: DiagramDraft) throws {
        guard let entity = try fetchDiagramEntity(id: id) else { return }
        entity.applyDraft(draft)
        try context.save()
    }

    func setFavorite(id: UUID, isFavorite: Bool) throws {
        guard let entity = try fetchDiagramEntity(id: id) else { return }
        entity.isFavorite = isFavorite
        entity.updatedAt = .now
        try context.save()
    }

    func markOpened(id: UUID, at: Date) throws {
        guard let entity = try fetchDiagramEntity(id: id) else { return }
        entity.lastOpenedAt = at
        entity.updatedAt = at
        try context.save()
    }

    func deleteDiagram(id: UUID) throws {
        guard let entity = try fetchDiagramEntity(id: id) else { return }
        context.delete(entity)
        try context.save()
    }

    func reorderDiagrams(in categoryID: UUID?, idsInOrder: [UUID]) throws {
        guard !idsInOrder.isEmpty else { return }
        let entities = try fetchDiagramEntities().filter { $0.category?.id == categoryID }
        let positions = Dictionary(uniqueKeysWithValues: idsInOrder.enumerated().map { ($0.element, $0.offset) })

        for entity in entities {
            guard let sortOrder = positions[entity.id] else { continue }
            entity.sortOrder = sortOrder
            entity.updatedAt = .now
        }

        try context.save()
    }

    func searchDiagrams(query: String) throws -> [Diagram] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return try fetchDiagrams(scope: .allDiagrams)
        }

        return try fetchDiagramEntities()
            .map { $0.toDomain() }
            .filter {
                $0.name.localizedCaseInsensitiveContains(normalized) ||
                $0.source.localizedCaseInsensitiveContains(normalized)
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.updatedAt > $1.updatedAt
                }
                return $0.sortOrder < $1.sortOrder
            }
    }

    func seedInitialContentIfNeeded() throws {
        let existing = try context.fetch(FetchDescriptor<DiagramEntity>())
        guard existing.isEmpty else { return }

        let category = CategoryEntity(
            name: "Workspace",
            iconSystemName: "sparkles.rectangle.stack",
            colorHex: "#53C3B0",
            sortOrder: 0
        )
        let diagram = DiagramEntity(
            name: "Studio Overview",
            source: MermaidDocumentSamples.defaultDiagram,
            previewThemeID: MermaidThemePreset.defaultPreset.id,
            exportBackgroundModeRaw: MermaidExportBackgroundStyle.Mode.theme.rawValue,
            exportBackgroundColorHex: "#FFFFFF",
            isFavorite: true,
            lastOpenedAt: .now,
            sortOrder: 0,
            category: category
        )

        context.insert(category)
        context.insert(diagram)
        try context.save()
    }

    private func fetchDiagramEntities() throws -> [DiagramEntity] {
        try context.fetch(
            FetchDescriptor<DiagramEntity>(
                sortBy: [
                    SortDescriptor(\.sortOrder),
                    SortDescriptor(\.updatedAt, order: .reverse)
                ]
            )
        )
    }

    private func fetchDiagramEntity(id: UUID) throws -> DiagramEntity? {
        let descriptor = FetchDescriptor<DiagramEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    private func fetchCategoryEntity(id: UUID) throws -> CategoryEntity? {
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try context.fetch(descriptor).first
    }

    private func nextDiagramSortOrder(in categoryID: UUID?) -> Int {
        let diagrams = (try? fetchDiagramEntities()) ?? []
        let scoped = diagrams.filter { $0.category?.id == categoryID }
        return (scoped.map(\.sortOrder).max() ?? -1) + 1
    }

    private func normalizedName(_ rawName: String, fallback: String) -> String {
        let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
