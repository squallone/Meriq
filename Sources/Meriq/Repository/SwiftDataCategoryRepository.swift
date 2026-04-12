//
//  SwiftDataCategoryRepository.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

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
