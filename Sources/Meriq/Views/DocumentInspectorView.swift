//
//  DocumentInspectorView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct DocumentInspectorView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore

    var showHeader = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if showHeader {
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
            .padding(.bottom, 18)
        }
        .scrollIndicators(.visible)
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
