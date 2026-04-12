//
//  StudioSidebarView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
