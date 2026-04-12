//
//  TemplateListView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

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
