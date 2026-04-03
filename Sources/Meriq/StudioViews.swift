import AppKit
import SwiftUI

private enum StudioChrome {
    static let windowTop = Color(red: 0.06, green: 0.07, blue: 0.10)
    static let windowBottom = Color(red: 0.04, green: 0.05, blue: 0.07)

    static let sidebarStart = Color(red: 0.08, green: 0.14, blue: 0.24)
    static let sidebarMid = Color(red: 0.10, green: 0.18, blue: 0.31)
    static let sidebarEnd = Color(red: 0.06, green: 0.29, blue: 0.39)
    static let sidebarVeil = Color(red: 0.06, green: 0.08, blue: 0.12).opacity(0.64)

    static let workspaceTop = Color(red: 0.08, green: 0.09, blue: 0.12)
    static let workspaceBottom = Color(red: 0.05, green: 0.06, blue: 0.08)

    static let surfacePrimary = Color(red: 0.11, green: 0.12, blue: 0.16)
    static let surfaceSecondary = Color(red: 0.09, green: 0.11, blue: 0.15)
    static let surfaceElevated = Color(red: 0.13, green: 0.15, blue: 0.20)
    static let surfaceSelected = Color(red: 0.19, green: 0.24, blue: 0.33)

    static let panelFill = Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.96)
    static let panelInnerFill = Color(red: 0.08, green: 0.10, blue: 0.14)

    static let previewOuterTop = Color(red: 0.08, green: 0.15, blue: 0.18)
    static let previewOuterBottom = Color(red: 0.08, green: 0.14, blue: 0.25)
    static let previewGridBase = Color(red: 0.07, green: 0.10, blue: 0.14)
    static let previewGridInset = Color(red: 0.05, green: 0.08, blue: 0.11)

    static let borderSoft = Color.white.opacity(0.06)
    static let borderStrong = Color.white.opacity(0.10)
    static let divider = Color.white.opacity(0.05)

    static let textPrimary = Color.white.opacity(0.96)
    static let textSecondary = Color.white.opacity(0.68)
    static let textTertiary = Color.white.opacity(0.50)

    static let accentMint = Color(red: 0.27, green: 0.80, blue: 0.68)
    static let accentBlue = Color(red: 0.38, green: 0.56, blue: 0.97)
}

struct RootStudioView: View {
    @EnvironmentObject private var libraryStore: LibraryStore

    var body: some View {
        NavigationSplitView {
            StudioSidebarView()
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 340)
        } detail: {
            if libraryStore.isShowingTemplates {
                TemplateWorkspaceView()
            } else {
                StudioWorkspaceContainer()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .background(
            LinearGradient(
                colors: [StudioChrome.windowTop, StudioChrome.windowBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .sheet(isPresented: $libraryStore.isPresentingCategoryEditor) {
            CategoryEditorSheet()
        }
        .alert("Delete Category?", isPresented: Binding(
            get: { libraryStore.pendingCategoryDelete != nil },
            set: { if !$0 { libraryStore.clearCategoryDeleteConfirmation() } }
        )) {
            Button("Delete", role: .destructive) {
                libraryStore.deletePendingCategory()
            }
            Button("Cancel", role: .cancel) {
                libraryStore.clearCategoryDeleteConfirmation()
            }
        } message: {
            Text("Diagrams in this category will move to Uncategorized.")
        }
        .overlay(alignment: .bottomLeading) {
            if let message = libraryStore.lastErrorMessage {
                StudioBanner(message: message)
                    .padding(16)
            }
        }
    }
}

struct StudioSidebarView: View {
    @EnvironmentObject private var libraryStore: LibraryStore

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [StudioChrome.sidebarEnd, StudioChrome.sidebarMid, StudioChrome.sidebarStart],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            Rectangle()
                .fill(StudioChrome.sidebarVeil)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(StudioChrome.divider)
                .frame(width: 1)
        }
        .overlay {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    sidebarHeader
                    searchField
                    smartSection
                    categoriesSection
                    Spacer(minLength: 28)
                }
                .padding(18)
            }
        }
    }

    private var sidebarHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Meriq")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(StudioChrome.textPrimary)
                Text("Library")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(StudioChrome.textSecondary)
            }

            Spacer()

            Button {
                libraryStore.createDiagram()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(StudioChrome.textTertiary)
            TextField("Search diagrams", text: Binding(
                get: { libraryStore.searchText },
                set: { libraryStore.updateSearchText($0) }
            ))
            .textFieldStyle(.plain)
            .foregroundStyle(StudioChrome.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(StudioChrome.surfaceElevated.opacity(0.88))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(StudioChrome.borderSoft, lineWidth: 1)
        )
    }

    private var smartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Library")

            SidebarScopeButton(
                title: "All Diagrams",
                subtitle: "Browse the full library",
                symbolName: "rectangle.stack",
                isSelected: libraryStore.sidebarSelection == .allDiagrams,
                isExpanded: libraryStore.isInlineBrowserExpanded(for: .allDiagrams),
                action: { libraryStore.selectSidebar(.allDiagrams) }
            )

            if libraryStore.isInlineBrowserExpanded(for: .allDiagrams) {
                SidebarInlineBrowser(
                    sections: libraryStore.sidebarDiagramSections(for: .allDiagrams)
                )
            }

            SidebarScopeButton(
                title: "Recents",
                subtitle: "Recently opened",
                symbolName: "clock.arrow.circlepath",
                isSelected: libraryStore.sidebarSelection == .recents,
                isExpanded: libraryStore.isInlineBrowserExpanded(for: .recents),
                action: { libraryStore.selectSidebar(.recents) }
            )

            if libraryStore.isInlineBrowserExpanded(for: .recents) {
                SidebarInlineBrowser(
                    sections: libraryStore.sidebarDiagramSections(for: .recents),
                    style: .flat
                )
            }

            SidebarScopeButton(
                title: "Favorites",
                subtitle: "Pinned working files",
                symbolName: "star",
                isSelected: libraryStore.sidebarSelection == .favorites,
                isExpanded: libraryStore.isInlineBrowserExpanded(for: .favorites),
                action: { libraryStore.selectSidebar(.favorites) }
            )

            if libraryStore.isInlineBrowserExpanded(for: .favorites) {
                SidebarInlineBrowser(
                    sections: libraryStore.sidebarDiagramSections(for: .favorites),
                    style: .flat
                )
            }

            SidebarScopeButton(
                title: "Templates",
                subtitle: "Starter Mermaid patterns",
                symbolName: "square.stack.3d.up",
                isSelected: libraryStore.sidebarSelection == .templates,
                isExpanded: false,
                action: { libraryStore.selectSidebar(.templates) }
            )
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionHeader("Categories")
                Spacer()
                Button {
                    libraryStore.presentNewCategorySheet()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white.opacity(0.75))
            }

            SidebarScopeButton(
                title: "Uncategorized",
                subtitle: "Loose working files",
                symbolName: "tray",
                isSelected: libraryStore.sidebarSelection == .uncategorized,
                isExpanded: libraryStore.isInlineBrowserExpanded(for: .uncategorized),
                action: { libraryStore.selectSidebar(.uncategorized) }
            )

            if libraryStore.isInlineBrowserExpanded(for: .uncategorized) {
                SidebarInlineBrowser(
                    sections: libraryStore.sidebarDiagramSections(for: .uncategorized),
                    style: .flat
                )
            }

            ForEach(libraryStore.categories) { category in
                SidebarCategoryButton(
                    category: category,
                    isSelected: libraryStore.sidebarSelection == .category(category.id),
                    isExpanded: libraryStore.isInlineBrowserExpanded(for: .category(category.id)),
                    action: { libraryStore.selectSidebar(.category(category.id)) },
                    onEdit: { libraryStore.presentEditCategorySheet(category) },
                    onDelete: { libraryStore.confirmDeleteCategory(category) }
                )

                if libraryStore.isInlineBrowserExpanded(for: .category(category.id)) {
                    SidebarInlineBrowser(
                        sections: libraryStore.sidebarDiagramSections(for: .category(category.id)),
                        style: .flat
                    )
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(StudioChrome.textSecondary)
            .textCase(nil)
    }
}

struct SidebarScopeButton: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? StudioChrome.textPrimary : StudioChrome.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(StudioChrome.textSecondary)
                }

                Spacer()

                if isExpanded {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(StudioChrome.textSecondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(StudioChrome.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? StudioChrome.surfaceSelected.opacity(0.94) : StudioChrome.surfaceSecondary.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? StudioChrome.borderStrong : StudioChrome.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SidebarCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hexString: category.colorHex ?? "#53C3B0").opacity(0.20))
                    Image(systemName: category.iconSystemName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hexString: category.colorHex ?? "#53C3B0"))
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                    Text("\(category.diagramCount) diagrams")
                        .font(.system(size: 11))
                        .foregroundStyle(StudioChrome.textSecondary)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(StudioChrome.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? StudioChrome.surfaceSelected.opacity(0.94) : StudioChrome.surfaceSecondary.opacity(0.68))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? StudioChrome.borderStrong : StudioChrome.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit Category", action: onEdit)
            Button("Delete Category", role: .destructive, action: onDelete)
        }
    }
}

struct SidebarInlineBrowser: View {
    enum BrowserStyle {
        case grouped
        case flat
    }

    @EnvironmentObject private var libraryStore: LibraryStore

    let sections: [SidebarDiagramSection]
    var style: BrowserStyle = .grouped

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if sections.isEmpty {
                Text("No diagrams")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(StudioChrome.textTertiary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
            } else {
                ForEach(sections) { section in
                    if style == .grouped || sections.count > 1 {
                        sidebarSectionHeader(section)
                    }

                    ForEach(section.diagrams) { diagram in
                        SidebarDiagramButton(diagram: diagram)
                    }
                }
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .padding(.bottom, 6)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private func sidebarSectionHeader(_ section: SidebarDiagramSection) -> some View {
        HStack(spacing: 8) {
            Image(systemName: section.symbolName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hexString: section.tintHex ?? "#9AA7BF"))
            Text(section.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(StudioChrome.textSecondary)
            Spacer()
            Text("\(section.diagrams.count)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(StudioChrome.textTertiary)
        }
        .padding(.top, 4)
    }
}

struct SidebarDiagramButton: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore

    let diagram: Diagram

    var body: some View {
        Button {
            libraryStore.selectedDiagramID = diagram.id
        } label: {
            HStack(spacing: 10) {
                Image(systemName: diagram.isFavorite ? "star.fill" : "doc.text")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(diagram.isFavorite ? Color.yellow : StudioChrome.textSecondary)
                    .frame(width: 14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(diagram.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                        .lineLimit(1)
                    Text(diagram.source.components(separatedBy: .newlines).first ?? "Mermaid diagram")
                        .font(.system(size: 10))
                        .foregroundStyle(StudioChrome.textTertiary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(libraryStore.selectedDiagramID == diagram.id ? StudioChrome.surfaceSelected.opacity(0.96) : StudioChrome.surfaceSecondary.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(libraryStore.selectedDiagramID == diagram.id ? StudioChrome.borderStrong : StudioChrome.borderSoft.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(diagram.isFavorite ? "Remove Favorite" : "Add Favorite") {
                libraryStore.toggleFavorite(diagram)
            }

            Menu("Move To") {
                Button("Uncategorized") {
                    libraryStore.moveDiagram(diagram, to: nil)
                }
                ForEach(libraryStore.categories) { category in
                    Button(category.name) {
                        libraryStore.moveDiagram(diagram, to: category.id)
                    }
                }
            }

            Button("Delete Diagram", role: .destructive) {
                libraryStore.selectedDiagramID = diagram.id
                editorStore.flushAutosaveIfNeeded()
                libraryStore.deleteSelectedDiagram()
            }
        }
    }
}

struct TemplateWorkspaceView: View {
    @EnvironmentObject private var libraryStore: LibraryStore

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Templates")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Choose a starter and we’ll create a new diagram in your current library.")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 16)
            .background(StudioChrome.surfaceSecondary.opacity(0.84))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(StudioChrome.divider)
                    .frame(height: 1)
            }

            TemplateListView()
        }
        .background(
            LinearGradient(
                colors: [StudioChrome.workspaceTop, StudioChrome.workspaceBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

struct TemplateListView: View {
    @EnvironmentObject private var libraryStore: LibraryStore

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(libraryStore.templates) { template in
                    Button {
                        libraryStore.createDiagram(from: template)
                    } label: {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [StudioChrome.accentMint.opacity(0.28), StudioChrome.accentBlue.opacity(0.20)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Image(systemName: template.symbolName)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 68, height: 68)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.title)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(StudioChrome.textPrimary)
                                Text(template.subtitle)
                                    .font(.system(size: 12))
                                    .foregroundStyle(StudioChrome.textSecondary)
                                Text(template.source.components(separatedBy: .newlines).prefix(2).joined(separator: " "))
                                    .font(.system(size: 11))
                                    .foregroundStyle(StudioChrome.textSecondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Label("Use Template", systemImage: "arrow.right.circle.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(StudioChrome.panelFill)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(StudioChrome.borderSoft, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
    }
}

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

struct MermaidEditorView: View {
    @EnvironmentObject private var editorStore: EditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let draft = editorStore.draft {
                HStack(spacing: 12) {
                    TextField("Diagram Name", text: Binding(
                        get: { draft.name },
                        set: { editorStore.updateName($0) }
                    ))
                    .textFieldStyle(.roundedBorder)

                    Button {
                        editorStore.toggleFavorite()
                    } label: {
                        Label(
                            draft.isFavorite ? "Favorite" : "Add Favorite",
                            systemImage: draft.isFavorite ? "star.fill" : "star"
                        )
                    }
                    .buttonStyle(.bordered)
                }

                TextEditor(text: Binding(
                    get: { editorStore.draft?.source ?? "" },
                    set: { editorStore.updateSource($0) }
                ))
                .font(.system(size: 14, weight: .regular, design: .monospaced))
                .scrollContentBackground(.hidden)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(StudioChrome.panelFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(StudioChrome.borderSoft, lineWidth: 1)
                )
            }
        }
        .padding(22)
    }
}

struct PreviewDetailColumn: View {
    var body: some View {
        VStack(spacing: 18) {
            MermaidPreviewPane()
            DocumentInspectorView()
                .frame(minHeight: 320, idealHeight: 360, maxHeight: 420)
        }
        .padding(18)
    }
}

struct MermaidPreviewPane: View {
    @EnvironmentObject private var editorStore: EditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StudioChrome.textPrimary)
                Spacer()
            }

            MermaidWebView(webView: editorStore.renderer.webView)
                .frame(maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
                .background(
                    PreviewGridBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(StudioChrome.borderSoft, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PreviewGridBackground: View {
    var body: some View {
        Canvas { context, size in
            let background = Path(CGRect(origin: .zero, size: size))
            context.fill(
                background,
                with: .linearGradient(
                    Gradient(colors: [StudioChrome.previewGridBase, StudioChrome.previewGridInset]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )

            let spacing: CGFloat = 32
            var path = Path()

            stride(from: 0, through: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }

            stride(from: 0, through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }

            context.stroke(path, with: .color(Color.white.opacity(0.05)), lineWidth: 1)
        }
    }
}

struct DocumentInspectorView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Document")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                    Spacer()
                    if let draft = editorStore.draft {
                        Text(draft.id.uuidString.prefix(8))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(StudioChrome.textTertiary)
                    }
                }

                if let draft = editorStore.draft {
                    inspectorGroup("Status") {
                        HStack {
                            HStack(spacing: 10) {
                                Image(systemName: draft.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(draft.isFavorite ? Color.yellow : .white.opacity(0.5))
                                Text(draft.isFavorite ? "Favorited" : "Not favorited")
                                    .font(.system(size: 12))
                                    .foregroundStyle(StudioChrome.textSecondary)
                            }

                            HStack(spacing: 10) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundStyle(editorStore.isRendererError ? Color.red : Color.green)
                                Text(editorStore.isRendererError ? "Preview has rendering issues" : "Preview is up to date")
                                    .font(.system(size: 12))
                                    .foregroundStyle(StudioChrome.textSecondary)
                            }
                        }
                    }
                    
                    inspectorGroup("Name") {
                        TextField("Diagram Name", text: Binding(
                            get: { draft.name },
                            set: { editorStore.updateName($0) }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    inspectorGroup("Appearance") {
                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Theme", selection: Binding(
                                get: { draft.previewThemeID },
                                set: { editorStore.updateTheme($0) }
                            )) {
                                ForEach(editorStore.renderer.availableThemes) { theme in
                                    Text(theme.name).tag(theme.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Toggle(isOn: Binding(
                            get: { draft.previewThemeID == "midnight" },
                            set: { editorStore.updateTheme($0 ? "midnight" : MermaidThemePreset.defaultPreset.id) }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dark Document")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(StudioChrome.textPrimary)
                                Text("Switches the rendered document and canvas to a darker presentation.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(StudioChrome.textTertiary)
                            }
                        }
                        .toggleStyle(.switch)

                        VStack(alignment: .leading, spacing: 8) {
                            Picker("Background", selection: Binding(
                                get: { draft.exportBackground.mode },
                                set: { editorStore.updateExportMode($0) }
                            )) {
                                ForEach(MermaidExportBackgroundStyle.Mode.allCases) { mode in
                                    Text(mode.label).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        if draft.exportBackground.mode == .custom {
                            HStack(spacing: 10) {
                                ColorPicker("", selection: Binding(
                                    get: { Color(hexString: draft.exportBackground.customColorHex) },
                                    set: { editorStore.updateExportColor($0) }
                                ), supportsOpacity: false)
                                .labelsHidden()

                                Text(draft.exportBackground.customColorHex)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundStyle(StudioChrome.textSecondary)

                                Spacer()
                            }
                        }
                    }

                    inspectorGroup("Location") {
                        Picker("Category", selection: Binding(
                            get: { editorStore.selectedCategoryID },
                            set: { editorStore.updateCategoryID($0) }
                        )) {
                            Text("Uncategorized").tag(Optional<UUID>.none)
                            ForEach(libraryStore.categories) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(20)
        }
        .scrollIndicators(.visible)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(StudioChrome.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(StudioChrome.borderSoft, lineWidth: 1)
        )
    }

    private func inspectorGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(StudioChrome.textSecondary)
            content()
        }
    }
}

struct ExportPopoverView: View {
    @EnvironmentObject private var editorStore: EditorStore

    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Configure output for the selected diagram.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if editorStore.draft != nil {
                exportGroup("Format") {
                    Picker("Format", selection: $editorStore.exportConfiguration.variant) {
                        ForEach(MermaidExportVariant.allCases) { variant in
                            Text(variant.title).tag(variant)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                exportGroup("Output Size") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scale")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(editorStore.exportConfiguration.scale * 100))%")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $editorStore.exportConfiguration.scale, in: 1.0...4.0, step: 0.5)

                        HStack {
                            Text("100%")
                            Spacer()
                            Text("400%")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Button("Copy \(editorStore.exportConfiguration.variant.title)") {
                        editorStore.renderer.copyToClipboard(
                            variant: editorStore.exportConfiguration.variant,
                            scale: editorStore.exportConfiguration.scale
                        )
                        isPresented = false
                    }
                    .buttonStyle(.bordered)

                    Button("Export \(editorStore.exportConfiguration.variant.title)") {
                        editorStore.renderer.exportToFile(
                            variant: editorStore.exportConfiguration.variant,
                            scale: editorStore.exportConfiguration.scale
                        )
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Select a diagram to configure export.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 340)
    }

    private func exportGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            content()
        }
    }
}

struct CategoryEditorSheet: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(libraryStore.categoryDraft.id == nil ? "New Category" : "Edit Category")
                .font(.system(size: 22, weight: .semibold))

            TextField("Category Name", text: $libraryStore.categoryDraft.name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .font(.system(size: 13, weight: .semibold))
                IconPickerView(selectedIcon: $libraryStore.categoryDraft.iconSystemName)
            }

            HStack {
                Text("Tint")
                    .font(.system(size: 13, weight: .semibold))
                ColorPicker("", selection: Binding(
                    get: { Color(hexString: libraryStore.categoryDraft.colorHex) },
                    set: { libraryStore.categoryDraft.colorHex = $0.hexRGBString }
                ), supportsOpacity: false)
                .labelsHidden()
                Text(libraryStore.categoryDraft.colorHex)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save Category") {
                    libraryStore.saveCategoryDraft()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct IconPickerView: View {
    @Binding var selectedIcon: String

    private let columns = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MermaidStudioSymbols.categories, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedIcon == symbol ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selectedIcon == symbol ? Color.accentColor : Color.primary)
                        }
                        .frame(height: 54)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct StudioEmptyState: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [StudioChrome.accentMint.opacity(0.22), StudioChrome.accentBlue.opacity(0.16)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: 84, height: 84)

            Text(title)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.68))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)

            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

struct StudioBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.red.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.red.opacity(0.28), lineWidth: 1)
            )
            .foregroundStyle(Color.red)
    }
}
