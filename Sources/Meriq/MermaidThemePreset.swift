//
//  MermaidThemePreset.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

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
