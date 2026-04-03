# UI And Interaction Model

This document captures the current Meriq studio UX after the sidebar, inspector, export, and preview simplification work.

## Design Goals

The current UI is designed around five principles:

- local-first and studio-like, not document-browser-heavy
- native to macOS, with familiar sidebars, toolbars, menus, popovers, and sheets
- focused information hierarchy
- more space for editing and previewing
- scalable enough for future smart lists, drag-and-drop, and richer export options

## Primary Layout

The app is organized into three functional areas:

- sidebar
- workspace
- right-side detail column

### Sidebar

The sidebar is the navigation system for the library.

It contains:

- app/library header
- sidebar search
- smart sections
- categories
- inline nested diagram browser

The sidebar now owns diagram browsing so the main content area does not need a permanently visible diagram list column.

### Workspace

The workspace is the active document area.

It contains:

- title and scope context
- top-level actions such as new diagram, paste source, render, copy, export
- editor, split view, or preview mode

The workspace mode picker lives in the macOS toolbar principal item.

### Right Detail Column

The right detail column contains:

- the preview surface
- the document inspector

The preview is the primary flexible surface in the column. It no longer sits inside unnecessary nested cards.

## Sidebar Interaction Model

### Nested Browsing

`All Diagrams`, `Recents`, `Favorites`, `Uncategorized`, and category rows act like disclosure-style navigation entries.

When selected:

- the row becomes the active scope
- its nested diagram browser expands below it
- grouped rows appear inline without consuming a separate content column

This keeps the UI compact while still allowing direct access to diagrams.

### Search

Search now lives in the sidebar instead of a dedicated diagram column.

Behavior:

- search filters the visible diagrams for the current scope
- search also keeps the active browser expanded so users can understand where results belong

### Sidebar Context Menus

Diagram rows expose contextual actions:

- favorite or unfavorite
- move to category
- delete

Category rows expose:

- edit
- delete

This is more native to macOS than placing every action inside the inspector.

## Inspector Model

The inspector now has a focused role: document details.

It contains:

- name
- appearance
- location
- status

### Appearance

Appearance is part of the document because it changes how the selected diagram is presented.

Current controls:

- theme
- dark document toggle
- background mode
- custom background color when needed

This keeps document presentation with document properties rather than treating it like export-only state.

## Export Model

Export settings were intentionally moved out of the inspector.

The `Export` toolbar button opens a contextual popover for export-only concerns.

Current export groups:

- format
- output size
- final copy/export actions

This keeps export lightweight, contextual, and easy to extend later without bloating the main UI.

## Action Placement

### Toolbar

The toolbar/workspace header is the right place for:

- new diagram
- paste source
- render
- copy actions
- export entry point
- secondary document action menu

### Diagram Actions

Diagram-level actions live near the selected document or the selected row, not inside export settings.

Examples:

- favorite toggle in the editor header
- delete in the document action menu
- favorite and delete in sidebar context menus

## Preview Layout

The preview has been simplified to reduce chrome.

Current approach:

- a simple `Preview` heading
- the `WKWebView` filling the remaining available space
- the grid/canvas treatment applied directly behind the web view
- no unnecessary outer preview card

This keeps the preview visually important without making it feel boxed in.

## Midnight Theme Direction

Midnight is the visual foundation for the app.

Current color strategy:

- sidebar and workspace share a calmer blue-slate and teal dark range
- preview and document surfaces use related dark fills and borders
- accent colors are restrained and support hierarchy instead of competing with it

The goal is a cohesive system rather than separate themed sections.

## Future UX Extensions

The current interaction model is ready for:

- drag-and-drop reordering
- more templates and starter kits
- additional smart lists
- multi-selection
- richer document metadata
- expanded export presets

Recommended direction for future work:

- keep the sidebar focused on browse/select/manage
- keep the inspector focused on document details
- keep export contextual and separate
- preserve the preview as the most spacious surface in the detail column
