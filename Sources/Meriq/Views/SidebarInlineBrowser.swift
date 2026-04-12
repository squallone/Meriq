//
//  SidebarInlineBrowser.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
