# Architecture

This document describes the current Meriq app architecture, with a focus on persistence, state ownership, rendering, and the boundaries between them.

## Principles

The app is organized around a few simple rules:

- SwiftData is the source of truth for the library
- views render store state instead of talking to persistence directly
- the renderer is responsible for rendering and export, not document ownership
- UI-specific behavior such as sidebar expansion, preview tool state, and document panel state lives in stores

The goal is to keep the app easy to evolve without mixing persistence, rendering, and view concerns together.

## Layer Overview

Meriq has four main layers:

1. Persistence
2. Repository
3. State
4. Presentation and rendering

### Persistence

Persistence is implemented with SwiftData in:

- [StudioPersistence.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioPersistence.swift)

Persisted entities:

- `CategoryEntity`
- `DiagramEntity`

Stored fields cover:

- category name, icon, tint, sort order, timestamps
- diagram name, Mermaid source, theme, background mode, favorite state, recents metadata, sort order, timestamps

Important modeling rules:

- categories are single-level
- `sortOrder` is explicit for categories and diagrams
- deleting a category moves diagrams into uncategorized
- `Recents`, `Favorites`, `Templates`, and `All Diagrams` are derived scopes, not persisted categories
- `Uncategorized` is a special scope, not a system record

### Repository

Repositories translate between SwiftData and app-facing models.

Implementation:

- [StudioRepositories.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioRepositories.swift)

Protocols:

- `CategoryRepository`
- `DiagramRepository`

Responsibilities:

- fetch and map entities into plain models
- create, update, reorder, and delete categories and diagrams
- hide SwiftData fetch/save details from the rest of the app
- seed initial sample data on first launch

### Domain Models

App-facing types live in:

- [StudioModels.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioModels.swift)

Key types include:

- `Category`
- `Diagram`
- `DiagramDraft`
- `SidebarSelection`
- `DiagramScope`
- `WorkspaceMode`
- `PreviewToolMode`
- `DiagramPreviewZoomState`
- `MermaidExportConfiguration`
- `SidebarDiagramSection`

These types allow most UI code to stay independent of SwiftData model types.

## State Ownership

State is split between two stores.

Implementation:

- [StudioStores.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioStores.swift)

### `LibraryStore`

`LibraryStore` owns library navigation and browse state.

Responsibilities:

- current sidebar scope
- expanded inline browser section
- search text
- categories
- visible diagrams for the active scope
- selected diagram id
- category CRUD flows
- diagram movement and deletion flows
- regrouping sidebar sections after mutations

### `EditorStore`

`EditorStore` owns the active document and preview-adjacent state.

Responsibilities:

- current `DiagramDraft`
- selected category for the draft
- workspace mode
- document panel collapse and resize state
- export configuration
- preview zoom state
- preview tool mode and keyboard zoom-session state
- autosave scheduling and flush behavior
- source/name/theme/background updates
- copy/paste helpers
- renderer coordination

Autosave behavior:

- draft updates happen immediately
- persistence is debounced
- autosave is flushed on selection change and scene transitions

## Rendering And Export

Rendering is separated from document ownership.

### `MermaidRenderer`

Implementation:

- [MermaidRenderer.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidRenderer.swift)

Responsibilities:

- hold the current renderable draft snapshot
- render preview content
- copy/export SVG and PNG
- report render/export status back to stores

It does not own the source-of-truth draft.

### `MermaidRenderEngine`

Implementation:

- [MermaidRenderEngine.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidRenderEngine.swift)

Responsibilities:

- host the `WKWebView`
- load the bundled Mermaid HTML shell
- run preview/export JavaScript
- receive status callbacks from the page
- forward preview edit requests back into Swift
- recover when the WebKit content process reloads

### Mermaid Shell

Bundled web resources live in:

- [index.html](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/Resources/index.html)
- [mermaid.min.js](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/Resources/mermaid.min.js)

## Bidirectional Preview Editing

Meriq includes a first pass at preview-to-source editing.

Implementation:

- [MermaidSourceEditing.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MermaidSourceEditing.swift)

Current design:

- Swift remains the source of truth
- the preview emits structured edit requests
- the source editing engine maps requests back into Mermaid source
- the editor draft is updated, re-rendered, and autosaved through normal paths

Current supported cases are intentionally scoped:

- flowchart node labels
- flowchart edge labels

This keeps the architecture scalable as more Mermaid syntaxes are added later.

## UI Composition

Main SwiftUI composition lives in:

- [StudioViews.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/StudioViews.swift)

Top-level structure:

- `RootStudioView`
- `StudioSidebarView`
- `StudioWorkspaceContainer`
- `MermaidEditorView`
- `PreviewDetailColumn`
- `MermaidPreviewPane`
- `DocumentBottomPanel`
- `DocumentInspectorView`
- `ExportPopoverView`
- `CategoryEditorSheet`

The app uses a `NavigationSplitView` with:

- a sidebar for navigation and inline browsing
- a detail area for editor and preview work

The preview column gives priority to the preview surface, with document details in a collapsible and resizable bottom panel.

## Startup And Dependency Wiring

Application setup happens in:

- [MeriqApp.swift](/Users/admin/Documents/Projects/iOS/Meriq/Sources/Meriq/MeriqApp.swift)

Startup flow:

- build the SwiftData schema and `ModelContainer`
- initialize repository implementations with `mainContext`
- initialize `LibraryStore`
- initialize `EditorStore`
- inject stores and model container into the SwiftUI tree

## Extension Points

The current architecture is prepared for:

- drag-and-drop polish
- richer smart lists
- more preview tools
- richer metadata
- expanded export presets
- import/export workflows
- tests around repositories, stores, preview tools, and source editing

Recommended approach for future changes:

- add or adjust persistence behind repositories first
- keep document state in stores
- keep rendering logic in renderer/engine layers
- avoid pushing source-of-truth state into the WebView layer
