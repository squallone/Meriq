import Foundation
import SwiftData

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconSystemName: String
    var colorHex: String?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \DiagramEntity.category)
    var diagrams: [DiagramEntity]

    init(
        id: UUID = UUID(),
        name: String,
        iconSystemName: String = "folder",
        colorHex: String? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.iconSystemName = iconSystemName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.diagrams = []
    }
}

@Model
final class DiagramEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var source: String
    var previewThemeID: String
    var exportBackgroundModeRaw: String
    var exportBackgroundColorHex: String
    var isFavorite: Bool
    var lastOpenedAt: Date?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
    var category: CategoryEntity?

    init(
        id: UUID = UUID(),
        name: String,
        source: String,
        previewThemeID: String = MermaidThemePreset.defaultPreset.id,
        exportBackgroundModeRaw: String = MermaidExportBackgroundStyle.Mode.theme.rawValue,
        exportBackgroundColorHex: String = "#FFFFFF",
        isFavorite: Bool = false,
        lastOpenedAt: Date? = nil,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        category: CategoryEntity? = nil
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.previewThemeID = previewThemeID
        self.exportBackgroundModeRaw = exportBackgroundModeRaw
        self.exportBackgroundColorHex = exportBackgroundColorHex
        self.isFavorite = isFavorite
        self.lastOpenedAt = lastOpenedAt
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
    }
}

extension CategoryEntity {
    func toDomain() -> Category {
        Category(
            id: id,
            name: name,
            iconSystemName: iconSystemName,
            colorHex: colorHex,
            sortOrder: sortOrder,
            diagramCount: diagrams.count
        )
    }
}

extension DiagramEntity {
    func toDomain() -> Diagram {
        Diagram(
            id: id,
            categoryID: category?.id,
            name: name,
            source: source,
            previewThemeID: previewThemeID,
            exportBackground: MermaidExportBackgroundStyle(
                mode: MermaidExportBackgroundStyle.Mode(rawValue: exportBackgroundModeRaw) ?? .theme,
                customColorHex: exportBackgroundColorHex
            ),
            isFavorite: isFavorite,
            lastOpenedAt: lastOpenedAt,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func applyDraft(_ draft: DiagramDraft) {
        name = draft.name
        source = draft.source
        previewThemeID = draft.previewThemeID
        exportBackgroundModeRaw = draft.exportBackground.mode.rawValue
        exportBackgroundColorHex = draft.exportBackground.customColorHex
        isFavorite = draft.isFavorite
        updatedAt = .now
    }
}
