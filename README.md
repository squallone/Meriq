# Meriq

![Meriq app icon](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/Resources/Assets.xcassets/AppIcon.appiconset/appicon_512.png)

Meriq is a local-first Mermaid studio for macOS. It combines a real diagram library, a native SwiftUI workspace, and a WebKit-based Mermaid preview so diagrams can be organized, edited, rendered, and exported without leaving the app.

![Meriq app preview](/Users/admin/Documents/Projects/iOS/Meriq/docs/images/app-preview.svg)

## Highlights

- Local-first library backed by SwiftData
- Categories with SF Symbol icons, color accents, and stable ordering
- Named diagrams, favorites, recents, templates, and uncategorized files
- Native macOS sidebar browsing with inline nested diagram lists
- Editor, split, and preview workspace modes
- Live Mermaid rendering in a bundled WebView preview
- Bidirectional editing for supported preview labels back into Mermaid source
- Contextual export flow for SVG and PNG
- Midnight-themed studio UI built around preview-first workflows

## Why Meriq

Most Mermaid tools are either text editors with a basic preview or browser-based utilities with little document organization. Meriq is designed as a real desktop workspace:

- your diagrams live in a library, not in loose files or a single scratch buffer
- browsing and editing are separated cleanly
- export is contextual, not mixed into document settings
- the preview is treated as a first-class canvas

## Current Feature Set

### Library

- Create, rename, move, favorite, and delete diagrams
- Create, edit, reorder, and delete categories
- Browse diagrams from `All Diagrams`, `Recents`, `Favorites`, `Templates`, `Uncategorized`, and category scopes
- Search from the sidebar instead of a dedicated diagram column

### Editing

- Edit Mermaid source in a monospaced editor
- Rename diagrams inline from the workspace
- Switch between `Editor`, `Split View`, and `Preview`
- Use a collapsible and resizable bottom document panel
- Update theme, dark document mode, background mode, and category assignment from the document panel

### Preview

- Render Mermaid locally in a bundled `WKWebView`
- Edit supported labels directly from the preview and sync them back into source
- Use keyboard-driven zoom tools and direct zoom controls in the preview header

### Export

- Copy Mermaid source
- Copy SVG or rendered PNG
- Export SVG or PNG from a dedicated export popover

## Screens And UX Model

Meriq follows a studio layout with three main areas:

- Sidebar: navigation, search, smart scopes, categories, and inline diagram browsing
- Workspace: editor and top-level document actions
- Preview column: preview canvas plus the bottom document panel

Notable UX decisions:

- The old always-visible diagram list column is gone to reclaim space for editing and previewing.
- Export settings are separated from document settings.
- The preview stays visually primary, while document details live in a flexible bottom panel.
- Midnight is the base visual system across sidebar, workspace, and preview surfaces.

## Architecture

Meriq uses a repository-backed app architecture:

- SwiftData is the source of truth
- repositories isolate persistence details from views
- `LibraryStore` owns navigation, browsing, CRUD, and selection
- `EditorStore` owns the active draft, autosave, preview tool state, and renderer coordination
- `MermaidRenderer` and `MermaidRenderEngine` handle rendering/export, not document ownership

Deeper documentation:

- [Architecture](/Users/admin/Documents/Projects/iOS/Meriq/docs/architecture.md)
- [UI and interaction model](/Users/admin/Documents/Projects/iOS/Meriq/docs/ui.md)
- [Distribution notes](/Users/admin/Documents/Projects/iOS/Meriq/docs/distribution.md)

## Project Layout

Main app sources live in [/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq):

- [MeriqApp.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MeriqApp.swift): app bootstrap and dependency wiring
- [ContentView.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/ContentView.swift): lifecycle coordination
- [StudioModels.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioModels.swift): app-facing models and enums
- [StudioPersistence.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioPersistence.swift): SwiftData entities and mapping helpers
- [StudioRepositories.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioRepositories.swift): repository protocols and implementations
- [StudioStores.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioStores.swift): `LibraryStore` and `EditorStore`
- [StudioViews.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioViews.swift): sidebar, workspace, preview, panel, sheets, and popovers
- [MermaidConfiguration.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidConfiguration.swift): themes, export configuration, preview request types
- [MermaidRenderer.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidRenderer.swift): preview/export orchestration
- [MermaidRenderEngine.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidRenderEngine.swift): WebKit bridge and Mermaid shell integration
- [MermaidSourceEditing.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidSourceEditing.swift): preview-to-source editing support

## Getting Started

### Requirements

- macOS 14 or later
- Xcode 16 or newer
- Swift 6 toolchain

### Build In Xcode

Open `Meriq.xcodeproj` and run the shared `Meriq` scheme.

### Build From Terminal

```bash
xcodebuild -project Meriq.xcodeproj \
  -scheme Meriq \
  -configuration Debug \
  -derivedDataPath .derivedData \
  build
```

The built app will be available at:

```text
.derivedData/Build/Products/Debug/Meriq.app
```

The Swift package target also builds:

```bash
swift build
```

## Development Scripts

Regenerate the Xcode project after moving or adding source files:

```bash
ruby Scripts/generate_xcodeproj.rb
```

Regenerate the app icon PNG set:

```bash
swift Scripts/generate_app_icon.swift
```

## Roadmap Ideas

- Broader bidirectional editing beyond the current supported Mermaid label cases
- Drag-and-drop ordering and movement polish
- Reset zoom / fit-to-canvas preview actions
- Richer metadata and tagging
- Import/export workflows for Mermaid files
- Tests around repositories, autosave, preview editing, and preview tools

## Contributing

Contributions are welcome. When making changes:

- keep the app local-first
- prefer native macOS interaction patterns over custom chrome
- preserve the separation between library state, document state, and rendering
- update docs when behavior or architecture changes

If you move files, regenerate the Xcode project with:

```bash
ruby Scripts/generate_xcodeproj.rb
```

## Open Source Notes

This repository does not currently include a license file, contribution guide, or code of conduct. If you plan to publish Meriq publicly, adding a `LICENSE`, `CONTRIBUTING.md`, and `CODE_OF_CONDUCT.md` would be a good next step.
