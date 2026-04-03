import Foundation
import CoreGraphics

enum SidebarSelection: Hashable {
    case recents
    case favorites
    case templates
    case allDiagrams
    case uncategorized
    case category(UUID)
}

enum WorkspaceMode: String, CaseIterable, Identifiable {
    case editor
    case split
    case preview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .editor:
            "Editor"
        case .split:
            "Split View"
        case .preview:
            "Preview"
        }
    }
}

enum PreviewToolMode: Equatable {
    case none
    case zoomIn
    case zoomOut

    var isActive: Bool {
        self != .none
    }

    var symbolName: String {
        switch self {
        case .none:
            "cursorarrow"
        case .zoomIn:
            "plus.magnifyingglass"
        case .zoomOut:
            "minus.magnifyingglass"
        }
    }

    var title: String {
        switch self {
        case .none:
            "Preview Tool"
        case .zoomIn:
            "Zoom In"
        case .zoomOut:
            "Zoom Out"
        }
    }

    var instruction: String {
        switch self {
        case .none:
            ""
        case .zoomIn:
            "Click the diagram to zoom in."
        case .zoomOut:
            "Click the diagram to zoom out."
        }
    }
}

enum DiagramScope: Equatable {
    case recents
    case favorites
    case allDiagrams
    case uncategorized
    case category(UUID)
}

struct Category: Identifiable, Equatable {
    let id: UUID
    var name: String
    var iconSystemName: String
    var colorHex: String?
    var sortOrder: Int
    var diagramCount: Int
}

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

struct SidebarDiagramSection: Identifiable, Equatable {
    let id: String
    let title: String
    let symbolName: String
    let tintHex: String?
    let diagrams: [Diagram]
}

struct MermaidExportConfiguration: Equatable {
    var variant: MermaidExportVariant = .svg
    var scale: Double = 2.0
}

struct DiagramPreviewZoomState: Equatable {
    static let defaultScale: CGFloat = 1.0
    static let minimumScale: CGFloat = 0.5
    static let maximumScale: CGFloat = 2.0
    static let step: CGFloat = 0.1

    var scale: CGFloat = defaultScale

    var canZoomIn: Bool {
        scale < Self.maximumScale - 0.001
    }

    var canZoomOut: Bool {
        scale > Self.minimumScale + 0.001
    }

    var percentageLabel: String {
        "\(Int((scale * 100).rounded()))%"
    }

    func zoomingIn() -> Self {
        var copy = self
        copy.scale = min(Self.maximumScale, scale + Self.step)
        return copy
    }

    func zoomingOut() -> Self {
        var copy = self
        copy.scale = max(Self.minimumScale, scale - Self.step)
        return copy
    }

    func resetting() -> Self {
        var copy = self
        copy.scale = Self.defaultScale
        return copy
    }
}

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

struct DiagramTemplate: Identifiable, Equatable {
    let id: UUID
    let title: String
    let subtitle: String
    let symbolName: String
    let source: String
}

enum MermaidStudioTemplates {
    static let all: [DiagramTemplate] = [
        DiagramTemplate(
            id: UUID(uuidString: "8D70BBA1-B773-4932-9A8D-D0A081306301") ?? UUID(),
            title: "Flowchart",
            subtitle: "Classic app and process flows",
            symbolName: "arrow.triangle.branch",
            source: """
            flowchart LR
                A[Start] --> B{Design approved?}
                B -->|Yes| C[Implement]
                B -->|No| D[Revise]
                C --> E[Ship]
                D --> A
            """
        ),
        DiagramTemplate(
            id: UUID(uuidString: "86A4B0DD-7E31-4B01-B0E2-9CC43A18F34B") ?? UUID(),
            title: "Sequence Diagram",
            subtitle: "API and collaboration flows",
            symbolName: "point.3.connected.trianglepath.dotted",
            source: """
            sequenceDiagram
                participant User
                participant App
                participant API
                User->>App: Create diagram
                App->>API: Sync metadata
                API-->>App: Persisted
                App-->>User: Success state
            """
        ),
        DiagramTemplate(
            id: UUID(uuidString: "6935CA12-D744-4E71-9A54-FEBA11161C17") ?? UUID(),
            title: "Gantt Chart",
            subtitle: "Roadmaps and delivery planning",
            symbolName: "chart.bar.xaxis",
            source: """
            gantt
                title Product Launch
                dateFormat  YYYY-MM-DD
                section Foundation
                Architecture      :done, a1, 2026-04-01, 5d
                Implementation    :active, a2, 2026-04-06, 8d
                section Launch
                QA                :2026-04-14, 4d
                Release           :2026-04-18, 2d
            """
        )
    ]
}

enum MermaidStudioSymbols {
    static let categories = [
        "folder",
        "folder.fill",
        "shippingbox",
        "tray.full",
        "books.vertical",
        "sparkles.rectangle.stack",
        "square.stack.3d.up",
        "briefcase",
        "tray.2",
        "person.2",
        "bolt.shield",
        "chart.xyaxis.line",
        "network",
        "server.rack",
        "terminal",
        "brain.head.profile",
        "wand.and.stars",
        "globe",
        "rectangle.3.group",
        "arrow.triangle.branch"
    ]
}
