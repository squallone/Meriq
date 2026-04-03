# UI And Interaction Model

This document describes the current Meriq UX and the information architecture behind it.

## Design Goals

The UI is designed around these goals:

- keep the preview prominent
- keep navigation compact and understandable
- stay native to macOS
- separate document settings from export settings
- make room for future features without reshaping the whole app

## Primary Layout

Meriq is organized into three functional areas:

- Sidebar
- Workspace
- Preview column

### Sidebar

The sidebar is the library browser.

It includes:

- app header
- diagram search
- smart scopes
- categories
- inline nested diagram browsing

The app no longer uses a permanently visible middle diagram list column. That space was reclaimed for editing and previewing.

### Workspace

The workspace is the active document surface.

It includes:

- current document or scope title
- high-level document actions
- the text editor when relevant

The `Editor / Split View / Preview` segmented control lives in the macOS toolbar principal item.

### Preview Column

The preview column contains:

- the preview surface
- a bottom document panel

The preview is visually primary. The document panel is available for quick access but does not permanently dominate the column.

## Sidebar Behavior

### Nested Browsing

These scopes support inline browser expansion:

- `All Diagrams`
- `Recents`
- `Favorites`
- `Uncategorized`
- user categories

When one of these scopes is selected:

- it becomes the active scope
- its inline browser expands beneath it
- grouped diagram rows appear directly in the sidebar

This keeps navigation compact without hiding access to diagrams.

### Search

Search lives in the sidebar rather than in a separate diagram column.

Behavior:

- it filters diagrams in the current scope
- it keeps the active inline browser expanded to preserve context

### Sidebar Context Menus

Diagram rows expose contextual actions such as:

- favorite or unfavorite
- move to category
- delete

Category rows expose:

- edit
- delete

This keeps operational actions near the selected item, which is more native on macOS than forcing everything into panels.

## Workspace Header

The workspace header is for top-level document commands.

It currently hosts:

- new diagram
- document actions menu
- paste source
- render
- copy menu
- export button

The workspace header is not used for detailed settings. It is intentionally action-oriented.

## Document Panel

The document area is a bottom utility panel below the preview.

Behavior:

- collapsible
- resizable with a dedicated grab handle
- preview-first by default
- still fast to reopen when document settings are needed

Current content groups:

- status
- name
- appearance
- location

### Appearance

Appearance is treated as a document concern.

Current controls:

- theme
- dark document mode
- background mode
- custom color when applicable

This keeps “how the document is presented” with document settings instead of export-only controls.

## Export Interaction

Export settings are intentionally not in the document panel.

The `Export` button opens a contextual popover for:

- output format
- scale
- export actions

That keeps export lightweight and avoids mixing output configuration with document metadata.

## Preview Interaction

The preview is a `WKWebView`-backed Mermaid canvas with a simplified chrome model:

- a `Preview` heading
- compact zoom controls
- the web view filling the remaining space
- a subtle grid/canvas background

The preview is designed to feel more like a working surface than a card full of nested containers.

## Preview Editing

Supported preview labels can be edited directly from the rendered diagram.

Current behavior:

- double-click a supported label in the preview
- edit it inline
- commit changes back into Mermaid source
- the editor updates automatically through the shared draft state

Current support is intentionally scoped to selected flowchart labels.

## Zoom Model

Meriq uses two zoom interaction styles:

- preview header buttons zoom immediately
- keyboard zoom shortcuts activate a temporary held zoom tool

The keyboard model is inspired by design tools:

- hold `Z` for zoom in
- hold `Z` and `Option` for zoom out
- release `Option` to switch back to zoom in
- release `Z` to end the temporary keyboard zoom session

This keeps the keyboard path tool-like while keeping the visible UI controls straightforward.

## Midnight Theme

Midnight is the visual foundation for the app.

Current direction:

- sidebar, workspace, preview, and document surfaces share one dark visual system
- chrome uses calmer blue-slate and teal values rather than competing themes
- accent colors are used sparingly for focus, state, and preview affordances

The goal is cohesion, not “each area has its own palette.”

## Future UI Direction

The current structure is ready for:

- richer drag-and-drop behavior
- fit-to-canvas and additional preview tools
- expanded metadata
- better multi-selection
- template browsing growth
- richer export presets

The main UX guidance for future work:

- keep navigation in the sidebar
- keep document settings in the document panel
- keep export contextual
- keep the preview visually dominant
