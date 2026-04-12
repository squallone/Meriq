//
//  CategoryEntity.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

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
