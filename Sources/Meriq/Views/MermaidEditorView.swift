//
//  MermaidEditorView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
