//
//  Diagram.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct Diagram: Identifiable, Equatable {
    let id: UUID
    var categoryID: UUID?
    var name: String
    var source: String
    var previewThemeID: String
    var exportBackground: MermaidExportBackgroundStyle
    var isFavorite: Bool
    var lastOpenedAt: Date?
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
}
