import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MermaidThemePreset: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let diagram: MermaidDiagramPalette
    let preview: MermaidPreviewPalette

    static let defaultPreset = graphite

    static let all: [MermaidThemePreset] = [
        midnight,
        sand,
        ocean,
        graphite
    ]

    static func preset(id: String) -> MermaidThemePreset {
        all.first(where: { $0.id == id }) ?? defaultPreset
    }

    private static let sand = MermaidThemePreset(
        id: "sand",
        name: "Sand",
        diagram: MermaidDiagramPalette(
            background: "#FFF9F0",
            primaryColor: "#F7C98F",
            primaryTextColor: "#2F2117",
            primaryBorderColor: "#8F5A2A",
            lineColor: "#69472A",
            secondaryColor: "#D4EBE2",
            tertiaryColor: "#D8E7FB",
            fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
        ),
        preview: MermaidPreviewPalette(
            pageStartColor: "#F5EFE5",
            pageEndColor: "#EBE0CF",
            glowColorOne: "rgba(249, 222, 201, 0.90)",
            glowColorTwo: "rgba(196, 225, 255, 0.85)",
            pageTextColor: "#24170F",
            canvasBackground: "rgba(255, 252, 246, 0.92)",
            canvasBorderColor: "rgba(94, 57, 31, 0.14)",
            canvasShadowColor: "rgba(97, 63, 36, 0.12)",
            captionBackground: "rgba(67, 104, 80, 0.08)",
            captionTextColor: "#33503D",
            errorBackground: "rgba(255, 236, 231, 0.92)",
            errorBorderColor: "rgba(153, 43, 28, 0.18)",
            errorTextColor: "#992B1C",
            placeholderBackground: "rgba(255, 255, 255, 0.75)",
            placeholderBorderColor: "rgba(63, 47, 32, 0.18)",
            placeholderTextColor: "rgba(36, 23, 15, 0.68)"
        )
    )

    private static let ocean = MermaidThemePreset(
        id: "ocean",
        name: "Ocean",
        diagram: MermaidDiagramPalette(
            background: "#F5FEFF",
            primaryColor: "#7FD7E0",
            primaryTextColor: "#12323A",
            primaryBorderColor: "#1B7A84",
            lineColor: "#1E5A63",
            secondaryColor: "#D8F1F3",
            tertiaryColor: "#E3F0FF",
            fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
        ),
        preview: MermaidPreviewPalette(
            pageStartColor: "#EAF7F8",
            pageEndColor: "#D7EAF0",
            glowColorOne: "rgba(108, 217, 220, 0.42)",
            glowColorTwo: "rgba(99, 140, 255, 0.28)",
            pageTextColor: "#10272D",
            canvasBackground: "rgba(250, 255, 255, 0.94)",
            canvasBorderColor: "rgba(23, 87, 97, 0.14)",
            canvasShadowColor: "rgba(16, 57, 70, 0.16)",
            captionBackground: "rgba(27, 122, 132, 0.10)",
            captionTextColor: "#1A6670",
            errorBackground: "rgba(255, 236, 231, 0.92)",
            errorBorderColor: "rgba(153, 43, 28, 0.18)",
            errorTextColor: "#992B1C",
            placeholderBackground: "rgba(255, 255, 255, 0.78)",
            placeholderBorderColor: "rgba(18, 50, 58, 0.14)",
            placeholderTextColor: "rgba(16, 39, 45, 0.62)"
        )
    )

    private static let graphite = MermaidThemePreset(
        id: "graphite",
        name: "Graphite",
        diagram: MermaidDiagramPalette(
            background: "#F5F6F8",
            primaryColor: "#D4D9E2",
            primaryTextColor: "#1E2530",
            primaryBorderColor: "#586173",
            lineColor: "#394252",
            secondaryColor: "#EAE6DB",
            tertiaryColor: "#DCE5F6",
            fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
        ),
        preview: MermaidPreviewPalette(
            pageStartColor: "#ECEFF3",
            pageEndColor: "#D8DDE7",
            glowColorOne: "rgba(119, 133, 168, 0.26)",
            glowColorTwo: "rgba(164, 178, 201, 0.34)",
            pageTextColor: "#1A2029",
            canvasBackground: "rgba(250, 251, 253, 0.95)",
            canvasBorderColor: "rgba(44, 53, 68, 0.12)",
            canvasShadowColor: "rgba(29, 37, 48, 0.14)",
            captionBackground: "rgba(57, 66, 82, 0.08)",
            captionTextColor: "#404C60",
            errorBackground: "rgba(255, 236, 231, 0.92)",
            errorBorderColor: "rgba(153, 43, 28, 0.18)",
            errorTextColor: "#992B1C",
            placeholderBackground: "rgba(255, 255, 255, 0.80)",
            placeholderBorderColor: "rgba(26, 32, 41, 0.14)",
            placeholderTextColor: "rgba(26, 32, 41, 0.62)"
        )
    )

    private static let midnight = MermaidThemePreset(
        id: "midnight",
        name: "Midnight",
        diagram: MermaidDiagramPalette(
            background: "#11161D",
            primaryColor: "#1F8A70",
            primaryTextColor: "#E7F3EE",
            primaryBorderColor: "#5ED5B6",
            lineColor: "#A3C8FF",
            secondaryColor: "#203041",
            tertiaryColor: "#2F243C",
            fontFamily: "SF Pro Text, -apple-system, BlinkMacSystemFont, sans-serif"
        ),
        preview: MermaidPreviewPalette(
            pageStartColor: "#091019",
            pageEndColor: "#0E1824",
            glowColorOne: "rgba(67, 188, 170, 0.14)",
            glowColorTwo: "rgba(90, 133, 240, 0.14)",
            pageTextColor: "#E7EDF7",
            canvasBackground: "rgba(16, 23, 33, 0.96)",
            canvasBorderColor: "rgba(144, 173, 230, 0.12)",
            canvasShadowColor: "rgba(0, 0, 0, 0.32)",
            captionBackground: "rgba(75, 189, 170, 0.10)",
            captionTextColor: "#8CDCD0",
            errorBackground: "rgba(70, 24, 24, 0.85)",
            errorBorderColor: "rgba(255, 122, 122, 0.18)",
            errorTextColor: "#FFB8B8",
            placeholderBackground: "rgba(255, 255, 255, 0.04)",
            placeholderBorderColor: "rgba(255, 255, 255, 0.12)",
            placeholderTextColor: "rgba(231, 237, 247, 0.62)"
        )
    )
}

struct MermaidDiagramPalette: Codable, Equatable {
    let background: String
    let primaryColor: String
    let primaryTextColor: String
    let primaryBorderColor: String
    let lineColor: String
    let secondaryColor: String
    let tertiaryColor: String
    let fontFamily: String
}

struct MermaidPreviewPalette: Codable, Equatable {
    let pageStartColor: String
    let pageEndColor: String
    let glowColorOne: String
    let glowColorTwo: String
    let pageTextColor: String
    let canvasBackground: String
    let canvasBorderColor: String
    let canvasShadowColor: String
    let captionBackground: String
    let captionTextColor: String
    let errorBackground: String
    let errorBorderColor: String
    let errorTextColor: String
    let placeholderBackground: String
    let placeholderBorderColor: String
    let placeholderTextColor: String
}

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

struct MermaidResolvedExportBackground: Codable, Equatable {
    let isTransparent: Bool
    let colorHex: String?
}

struct MermaidPreviewRequest: Codable, Equatable {
    let source: String
    let theme: MermaidThemePreset
    let padding: Double
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

extension NSColor {
    convenience init?(hexString: String) {
        let cleaned = hexString
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        guard cleaned.count == 6 || cleaned.count == 8 else {
            return nil
        }

        var value: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&value) else {
            return nil
        }

        let red: UInt64
        let green: UInt64
        let blue: UInt64
        let alpha: UInt64

        if cleaned.count == 8 {
            red = (value & 0xFF00_0000) >> 24
            green = (value & 0x00FF_0000) >> 16
            blue = (value & 0x0000_FF00) >> 8
            alpha = value & 0x0000_00FF
        } else {
            red = (value & 0xFF00_00) >> 16
            green = (value & 0x00FF_00) >> 8
            blue = value & 0x0000_FF
            alpha = 0xFF
        }

        self.init(
            red: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }

    var hexRGBString: String {
        let rgb = usingColorSpace(.deviceRGB) ?? self
        let red = Int(round(rgb.redComponent * 255))
        let green = Int(round(rgb.greenComponent * 255))
        let blue = Int(round(rgb.blueComponent * 255))
        return String(format: "#%02X%02X%02X", red, green, blue)
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
