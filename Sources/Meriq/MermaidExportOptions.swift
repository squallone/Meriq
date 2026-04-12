//
//  MermaidExportOptions.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidExportOptions: Codable, Equatable {
    var background = MermaidExportBackgroundStyle.theme
    var padding: Double = 28
    var scale: Double = 2.0
}

struct MermaidExportBackgroundStyle: Codable, Equatable {
    enum Mode: String, CaseIterable, Codable, Identifiable {
        case theme
        case transparent
        case custom

        var id: String { rawValue }

        var label: String {
            switch self {
            case .theme:
                "Theme"
            case .transparent:
                "Transparent"
            case .custom:
                "Custom"
            }
        }
    }

    var mode: Mode
    var customColorHex: String

    static let theme = MermaidExportBackgroundStyle(mode: .theme, customColorHex: "#FFFFFF")

    func resolvedBackground(theme: MermaidThemePreset) -> MermaidResolvedExportBackground {
        switch mode {
        case .theme:
            MermaidResolvedExportBackground(isTransparent: false, colorHex: theme.diagram.background)
        case .transparent:
            MermaidResolvedExportBackground(isTransparent: true, colorHex: nil)
        case .custom:
            MermaidResolvedExportBackground(isTransparent: false, colorHex: customColorHex)
        }
    }
}
