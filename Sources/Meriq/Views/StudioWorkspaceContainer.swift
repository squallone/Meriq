//
//  StudioWorkspaceContainer.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct StudioWorkspaceContainer: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore
    @State private var isShowingExportPopover = false

    var body: some View {
        VStack(spacing: 0) {
            workspaceHeader

            if editorStore.draft == nil {
                StudioEmptyState(
                    title: "Choose a diagram to start editing",
                    message: "Browse diagrams directly in the sidebar, then use the extra room here for editing and previewing.",
                    buttonTitle: "Create Diagram",
                    action: libraryStore.createDiagram
                )
            } else {
                HSplitView {
                    if editorStore.workspaceMode != .preview {
                        MermaidEditorView()
                            .frame(minWidth: editorStore.workspaceMode == .split ? 480 : 840)
                    }

                    if editorStore.workspaceMode == .split || editorStore.workspaceMode == .preview {
                        PreviewDetailColumn()
                            .frame(minWidth: 460)
                    }
                }
            }

            statusBar
        }
        .background(
            LinearGradient(
                colors: [StudioChrome.workspaceTop, StudioChrome.workspaceBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $editorStore.workspaceMode) {
                    ForEach(WorkspaceMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 260)
            }
        }
    }

    private var workspaceHeader: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(editorStore.draft?.name ?? libraryStore.activeScopeTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(StudioChrome.textPrimary)
                Text(libraryStore.activeScopeSubtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(StudioChrome.textSecondary)
            }

            Spacer()

            Button {
                libraryStore.createDiagram()
            } label: {
                Label("New Diagram", systemImage: "plus")
            }
            .buttonStyle(.bordered)

            if editorStore.draft != nil {
                Menu {
                    Button {
                        editorStore.toggleFavorite()
                    } label: {
                        Label(
                            editorStore.draft?.isFavorite == true ? "Remove Favorite" : "Add Favorite",
                            systemImage: editorStore.draft?.isFavorite == true ? "star.slash" : "star"
                        )
                    }

                    Divider()

                    Button(role: .destructive) {
                        editorStore.flushAutosaveIfNeeded()
                        libraryStore.deleteSelectedDiagram()
                    } label: {
                        Label("Delete Diagram", systemImage: "trash")
                    }
                } label: {
                    Label("Diagram", systemImage: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Button("Paste Source") {
                editorStore.pasteSourceFromClipboard()
            }
            .buttonStyle(.bordered)

            Button("Render") {
                editorStore.renderPreview()
            }
            .buttonStyle(.borderedProminent)

            Menu("Copy") {
                Button("Mermaid Source") {
                    editorStore.copySourceToClipboard()
                }
                Button("SVG Markup") {
                    editorStore.renderer.copySVGToClipboard()
                }
                Button("Rendered PNG") {
                    editorStore.renderer.copyImageToClipboard()
                }
            }

            Button("Export") {
                isShowingExportPopover.toggle()
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $isShowingExportPopover, arrowEdge: .top) {
                ExportPopoverView(isPresented: $isShowingExportPopover)
                    .environmentObject(editorStore)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(StudioChrome.surfaceSecondary.opacity(0.84))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(StudioChrome.divider)
                .frame(height: 1)
        }
    }

    private var statusBar: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(editorStore.isRendererError ? Color.red : Color.green)
                .frame(width: 8, height: 8)
            Text(editorStore.statusMessage)
                .font(.system(size: 12))
                .foregroundStyle(editorStore.isRendererError ? Color.red : StudioChrome.textSecondary)
            Spacer()
            Text("The sidebar now handles browsing so this studio area stays focused on editing and preview.")
                .font(.system(size: 12))
                .foregroundStyle(StudioChrome.textTertiary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(StudioChrome.surfaceSecondary.opacity(0.84))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(StudioChrome.divider)
                .frame(height: 1)
        }
    }
}
