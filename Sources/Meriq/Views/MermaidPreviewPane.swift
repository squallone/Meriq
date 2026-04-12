//
//  MermaidPreviewPane.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct MermaidPreviewPane: View {
    @EnvironmentObject private var editorStore: EditorStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Preview")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(StudioChrome.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    Button {
                        editorStore.zoomOutPreviewImmediately()
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!editorStore.previewZoomState.canZoomOut)
                    .foregroundStyle(StudioChrome.textSecondary)
                    .help("Zoom Out")

                    Text(editorStore.previewZoomState.percentageLabel)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(StudioChrome.textSecondary)
                        .frame(minWidth: 44)

                    Button {
                        editorStore.zoomInPreviewImmediately()
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!editorStore.previewZoomState.canZoomIn)
                    .foregroundStyle(StudioChrome.textSecondary)
                    .help("Zoom In")
                }
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(StudioChrome.surfaceSecondary.opacity(0.92))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(StudioChrome.borderSoft, lineWidth: 1)
                )
            }

            ZStack {
                MermaidWebView(webView: editorStore.renderer.webView)
                    .frame(maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
                    .background(
                        PreviewGridBackground()
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    )

                if editorStore.previewToolMode.isActive {
                    PreviewToolOverlay(mode: editorStore.previewToolMode)
                }

                PreviewClickCaptureView(
                    mode: editorStore.previewToolMode,
                    onPreviewClick: { editorStore.performPreviewToolClick() }
                )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        editorStore.previewToolMode.isActive ? StudioChrome.accentMint.opacity(0.4) : StudioChrome.borderSoft,
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
