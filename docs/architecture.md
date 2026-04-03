# Architecture

This document describes the current Meriq studio architecture after the persistence, navigation, inspector, export, and Midnight UI refactors.

## Overview

Meriq is a local-library-first macOS app with three major layers:

- persistence: SwiftData entities and repository implementations
- state: app-facing stores that own selection, drafts, autosave, and UI state
- presentation: SwiftUI views for the sidebar, workspace, preview, inspector, popovers, and sheets

The goal is to keep persistence details out of most views and make the app easy to extend for future features like drag-and-drop, templates, smart lists, and deeper export options.

## Persistence Layer

SwiftData is the source of truth.

Entity types:

- `CategoryEntity`
- `DiagramEntity`

Stored concepts:

- categories with icon, optional tint, ordering, and timestamps
- diagrams with name, Mermaid source, theme, background mode, favorite state, recents metadata, ordering, and timestamps

Important rules:

- categories are single-level
- `sortOrder` is explicit for both categories and diagrams
- deleting a category moves diagrams to uncategorized rather than deleting them
- `Recents`, `Favorites`, `Templates`, and `All Diagrams` are derived UI scopes, not persisted category records
- `Uncategorized` is a special scope, not a persisted system category

Implementation files:

- [StudioPersistence.swift](../Sources/Meriq/StudioPersistence.swift)
- [StudioRepositories.swift](../Sources/Meriq/StudioRepositories.swift)

## Repository Layer

The repository layer isolates storage access from the rest of the app.

Protocols:

- `CategoryRepository`
- `DiagramRepository`

Concrete implementations:

- `SwiftDataCategoryRepository`
- `SwiftDataDiagramRepository`

Responsibilities:

- fetch and map persisted entities into domain models
- perform CRUD operations
- maintain deterministic ordering
- seed first-run sample content
- keep SwiftData-specific fetch/save details out of stores and views

## Domain Models

Plain app-facing models live in [StudioModels.swift](../Sources/Meriq/StudioModels.swift).

Key types:

- `Category`
- `Diagram`
- `DiagramDraft`
- `SidebarSelection`
- `DiagramScope`
- `WorkspaceMode`
- `MermaidExportConfiguration`
- `SidebarDiagramSection`

This keeps most UI logic away from SwiftData types.

## State Layer

### `LibraryStore`

`LibraryStore` owns library-level state and interactions.

Main responsibilities:

- current sidebar selection
- expanded inline browser section
- search text
- category list
- visible diagram list for the current scope
- selected diagram identity
- category CRUD
- diagram list CRUD and movement
- reloads after repository mutations

It also builds grouped sidebar sections for:

- all diagrams
- recents
- favorites
- uncategorized
- user categories

### `EditorStore`

`EditorStore` owns the active document state.

Main responsibilities:

- current `DiagramDraft`
- selected category for the draft
- workspace mode: editor, split, preview
- autosave scheduling and flush behavior
- content, name, theme, and background updates
- copy/paste convenience actions
- delegating preview and export work to `MermaidRenderer`

Autosave behavior:

- edits update the draft immediately
- autosave runs on a debounce
- autosave also flushes on selection changes and scene transitions

Implementation file:

- [StudioStores.swift](../Sources/Meriq/StudioStores.swift)

## Rendering Layer

Rendering is intentionally separate from persistence.

### `MermaidRenderer`

`MermaidRenderer` owns:

- current renderable draft snapshot
- status reporting
- preview rendering
- clipboard copy actions
- file export actions

It does not own the source-of-truth document model.

### `MermaidRenderEngine`

`MermaidRenderEngine` is the low-level bridge to a `WKWebView` and the bundled Mermaid HTML shell.

It is responsible for:

- loading the local preview shell
- executing async JavaScript render/export functions
- receiving status callbacks from the web page
- reloading the shell if the web content process terminates

Implementation files:

- [MermaidRenderer.swift](../Sources/Meriq/MermaidRenderer.swift)
- [MermaidRenderEngine.swift](../Sources/Meriq/MermaidRenderEngine.swift)
- [index.html](../Sources/Meriq/Resources/index.html)

## UI Composition

The app uses a two-column `NavigationSplitView`:

- sidebar: library navigation and inline diagram browser
- detail: main workspace

Inside the detail area:

- editor-only mode shows the editor
- split mode shows editor plus preview/document column
- preview mode shows the preview/document column only

Primary views:

- `RootStudioView`
- `StudioSidebarView`
- `StudioWorkspaceContainer`
- `MermaidEditorView`
- `MermaidPreviewPane`
- `DocumentInspectorView`
- `ExportPopoverView`
- `CategoryEditorSheet`

Implementation file:

- [StudioViews.swift](../Sources/Meriq/StudioViews.swift)

## Information Architecture

The app now separates responsibilities more clearly:

- sidebar: navigation, search, selection, browse, quick diagram context menus
- workspace header: create, render, copy, export, document actions
- preview area: flexible primary rendering surface
- document inspector: name, appearance, location, status
- export popover: format, scale, copy/export actions

This split keeps export settings out of the inspector while keeping document appearance where it belongs.

## Theme System

Theme presets live in [MermaidConfiguration.swift](../Sources/Meriq/MermaidConfiguration.swift).

Current built-in themes:

- Midnight
- Sand
- Ocean
- Graphite

Midnight is the foundation for the app chrome and dark document presentation.

## App Startup

[MeriqApp.swift](../Sources/Meriq/MeriqApp.swift) builds the SwiftData container and wires dependencies:

- create SwiftData schema and `ModelContainer`
- initialize repositories with `container.mainContext`
- initialize `LibraryStore`
- initialize `EditorStore`
- inject both stores and the model container into the view tree

## Extension Points

The current architecture is prepared for:

- drag-and-drop reordering
- additional smart lists
- richer export configuration
- metadata/tagging
- sync or import/export features
- tests around repositories and stores

Recommended pattern for future work:

- add persistence changes behind repositories first
- keep UI derived from store state
- avoid pushing document source-of-truth back into the renderer
