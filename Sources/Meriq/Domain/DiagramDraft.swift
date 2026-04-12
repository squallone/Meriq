//
//  DiagramDraft.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//

import Foundation

struct DiagramDraft: Equatable {
    var id: UUID
    var name: String
    var source: String
    var previewThemeID: String
    var exportBackground: MermaidExportBackgroundStyle
    var isFavorite: Bool

    init(
        id: UUID,
        name: String,
        source: String,
        previewThemeID: String,
        exportBackground: MermaidExportBackgroundStyle,
        isFavorite: Bool
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.previewThemeID = previewThemeID
        self.exportBackground = exportBackground
        self.isFavorite = isFavorite
    }

    init(diagram: Diagram) {
        self.id = diagram.id
        self.name = diagram.name
        self.source = diagram.source
        self.previewThemeID = diagram.previewThemeID
        self.exportBackground = diagram.exportBackground
        self.isFavorite = diagram.isFavorite
    }
}
