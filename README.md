# Meriq

![Meriq app icon](Sources/Meriq/Resources/Assets.xcassets/AppIcon.appiconset/appicon_512.png)

Meriq is a local-first macOS Mermaid studio built with SwiftUI, SwiftData, and WebKit. It gives Mermaid diagrams a real library, a focused editor and preview workflow, and a native macOS UI for browsing, organizing, rendering, and exporting diagrams.

## Screenshot

![Meriq app preview](docs/images/app-preview.svg)

## What The App Does

- Stores diagrams locally with SwiftData
- Organizes diagrams into categories with icons and color tints
- Supports named diagrams, favorites, recents, uncategorized files, and starter templates
- Uses a nested sidebar browser instead of a permanently visible diagram list column
- Provides editor, split view, and preview modes from the macOS toolbar
- Renders Mermaid locally with a bundled WebKit-based preview shell
- Lets users copy or export SVG and PNG from a contextual export popover

## Current UX Model

The app now follows a three-part studio model:

- Sidebar: library navigation, search, smart sections, categories, and inline diagram browsing
- Workspace: the active editing surface and top-level document actions
- Right column: preview plus document details

Recent UX refinements include:

- removing the always-visible "All Diagrams" content column
- moving diagram search into the sidebar
- splitting document details from export configuration
- moving export options into a dedicated `Export` popover
- moving appearance controls back into the document area
- simplifying the preview layout so the canvas is the primary flexible surface
- aligning the Midnight theme across sidebar, preview, and document surfaces

## Project Structure

Top-level app files live in [Sources/Meriq](Sources/Meriq):

- [MeriqApp.swift](Sources/Meriq/MeriqApp.swift): app bootstrap, SwiftData container setup, store wiring
- [ContentView.swift](Sources/Meriq/ContentView.swift): lifecycle hooks and store synchronization
- [StudioModels.swift](Sources/Meriq/StudioModels.swift): domain models, sidebar selection, workspace modes, templates
- [StudioPersistence.swift](Sources/Meriq/StudioPersistence.swift): SwiftData entities and mapping helpers
- [StudioRepositories.swift](Sources/Meriq/StudioRepositories.swift): repository protocols and SwiftData implementations
- [StudioStores.swift](Sources/Meriq/StudioStores.swift): `LibraryStore` and `EditorStore`
- [StudioViews.swift](Sources/Meriq/StudioViews.swift): sidebar, workspace, preview, inspector, popovers, sheets
- [MermaidConfiguration.swift](Sources/Meriq/MermaidConfiguration.swift): Mermaid themes, preview palettes, export configuration models
- [MermaidRenderEngine.swift](Sources/Meriq/MermaidRenderEngine.swift): low-level `WKWebView` shell and JS bridge
- [MermaidRenderer.swift](Sources/Meriq/MermaidRenderer.swift): render/export orchestration for the selected draft

## Architecture

Meriq uses a repository-backed architecture:

- SwiftData is the source of truth for categories and diagrams
- repositories isolate persistence details from UI code
- `LibraryStore` owns library navigation, list state, sidebar expansion, category CRUD, diagram browsing, search, and selection
- `EditorStore` owns the active document draft, autosave, theme/background changes, and renderer coordination
- `MermaidRenderer` owns preview/export execution, but not the source of truth for the document

Detailed docs:

- [Architecture and persistence](docs/architecture.md)
- [UI and interaction model](docs/ui.md)
- [Distribution and notarization](docs/distribution.md)

## Build And Run

Open `Meriq.xcodeproj` in Xcode and run the shared `Meriq` scheme.

Build from Terminal:

```bash
xcodebuild -project Meriq.xcodeproj \
  -scheme Meriq \
  -configuration Debug \
  -derivedDataPath .derivedData \
  build
```

The built app is placed at:

```text
.derivedData/Build/Products/Debug/Meriq.app
```

The Swift package target also still builds:

```bash
swift build
```

## Project Scripts

Refresh the Xcode project after moving files:

```bash
ruby Scripts/generate_xcodeproj.rb
```

Regenerate the icon PNG set:

```bash
swift Scripts/generate_app_icon.swift
```

## Contributing

When making product changes:

- keep the app local-first and easy to understand
- prefer native macOS interaction patterns over custom complexity
- preserve the separation between navigation, document state, and export state
- update the docs when architecture or UX changes meaningfully

When moving source files, regenerate the Xcode project with `ruby Scripts/generate_xcodeproj.rb`.
