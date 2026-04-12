//
//  RootStudioView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct RootStudioView: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @EnvironmentObject private var editorStore: EditorStore

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
        .background(
            PreviewShortcutMonitor()
                .frame(width: 0, height: 0)
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
