//
//  TemplateWorkspaceView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
