import AppKit
import SwiftUI
import UniformTypeIdentifiers


struct MermaidResolvedExportBackground: Codable, Equatable {
    let isTransparent: Bool
    let colorHex: String?
}

struct MermaidPreviewRequest: Codable, Equatable {
    let source: String
    let theme: MermaidThemePreset
    let padding: Double
    let editableTokens: [MermaidEditableToken]
}

struct MermaidExportRequest: Codable, Equatable {
    let source: String
    let theme: MermaidThemePreset
    let background: MermaidResolvedExportBackground
    let padding: Double
    let scale: Double
}

struct MermaidSVGExportPayload: Codable {
    let svg: String
    let width: Double
    let height: Double
}

struct MermaidPNGExportPayload: Codable {
    let dataURL: String
    let width: Double
    let height: Double
}

enum MermaidExportVariant: String, CaseIterable, Identifiable {
    case svg
    case png

    var id: String { rawValue }

    var title: String {
        switch self {
        case .svg:
            "SVG"
        case .png:
            "PNG"
        }
    }

    var suggestedFilename: String {
        switch self {
        case .svg:
            "diagram.svg"
        case .png:
            "diagram.png"
        }
    }

    var savePanelTitle: String {
        switch self {
        case .svg:
            "Export SVG"
        case .png:
            "Export PNG"
        }
    }

    var savePanelMessage: String {
        switch self {
        case .svg:
            "Choose where to save the rendered SVG."
        case .png:
            "Choose where to save the rendered PNG."
        }
    }

    var allowedContentTypes: [UTType] {
        switch self {
        case .svg:
            [UTType(filenameExtension: "svg") ?? .xml]
        case .png:
            [.png]
        }
    }
}



extension Color {
    init(hexString: String) {
        self.init(nsColor: NSColor(hexString: hexString) ?? .white)
    }

    var hexRGBString: String {
        NSColor(self).hexRGBString
    }
}
