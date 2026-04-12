//
//  SidebarDiagramButton.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
