//
//  DocumentBottomPanel.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct DocumentBottomPanel: View {
    @EnvironmentObject private var editorStore: EditorStore
    @State private var dragStartHeight: CGFloat?
    @State private var isHoveringResizeHandle = false
    @State private var isDraggingResizeHandle = false

    let maxPanelHeight: CGFloat
    private let handleStripHeight: CGFloat = 18
    private let headerHeight: CGFloat = 58
    private let dividerHeight: CGFloat = 1

    var body: some View {
        let resolvedPanelHeight = min(editorStore.documentPanelHeight, maxPanelHeight)
        let bodyHeight = max(140, resolvedPanelHeight - handleStripHeight - headerHeight - dividerHeight)

        VStack(spacing: 0) {
            resizeHandle
            panelHeader

            if !editorStore.isDocumentPanelCollapsed {
                DocumentInspectorView(showHeader: false)
                    .frame(maxWidth: .infinity, minHeight: bodyHeight, idealHeight: bodyHeight, maxHeight: bodyHeight, alignment: .top)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: editorStore.isDocumentPanelCollapsed ? handleStripHeight + headerHeight : resolvedPanelHeight,
            idealHeight: editorStore.isDocumentPanelCollapsed ? handleStripHeight + headerHeight : resolvedPanelHeight,
            maxHeight: editorStore.isDocumentPanelCollapsed ? handleStripHeight + headerHeight : resolvedPanelHeight,
            alignment: .top
        )
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(StudioChrome.panelFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(StudioChrome.borderSoft, lineWidth: 1)
        )
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: editorStore.isDocumentPanelCollapsed)
        .animation(.spring(response: 0.24, dampingFraction: 0.88), value: editorStore.documentPanelHeight)
    }

    private var resizeHandle: some View {
        ZStack {
            Rectangle()
                .fill(isHoveringResizeHandle || isDraggingResizeHandle ? StudioChrome.surfaceElevated.opacity(0.65) : Color.clear)

            Capsule(style: .continuous)
                .fill(
                    isDraggingResizeHandle
                        ? StudioChrome.accentMint
                        : (isHoveringResizeHandle ? StudioChrome.textSecondary : StudioChrome.textTertiary.opacity(0.72))
                )
                .frame(width: isDraggingResizeHandle ? 50 : 42, height: 5)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(isHoveringResizeHandle || isDraggingResizeHandle ? 0.12 : 0.06), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(isHoveringResizeHandle || isDraggingResizeHandle ? 0.18 : 0.08), radius: 6, y: 1)
                .animation(.easeOut(duration: 0.16), value: isHoveringResizeHandle)
                .animation(.easeOut(duration: 0.16), value: isDraggingResizeHandle)
        }
        .frame(height: handleStripHeight)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHoveringResizeHandle = hovering
            if hovering {
                NSCursor.resizeUpDown.push()
            } else {
                NSCursor.pop()
            }
        }
        .gesture(resizeGesture)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(StudioChrome.divider.opacity(0.7))
                .frame(height: 1)
        }
    }

    private var panelHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Document")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(StudioChrome.textPrimary)

                Text(editorStore.isDocumentPanelCollapsed ? "Show document details" : "Drag to resize or collapse when you want more preview space")
                    .font(.system(size: 11))
                    .foregroundStyle(StudioChrome.textTertiary)
            }

            Spacer()

            if let draft = editorStore.draft, !editorStore.isDocumentPanelCollapsed {
                Text(draft.id.uuidString.prefix(8))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(StudioChrome.textTertiary)
            }

            Button {
                editorStore.toggleDocumentPanel()
            } label: {
                Image(systemName: editorStore.isDocumentPanelCollapsed ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(StudioChrome.textSecondary)
                    .frame(width: 26, height: 26)
                    .background(
                        Circle()
                            .fill(StudioChrome.surfaceElevated.opacity(0.88))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(height: headerHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            if editorStore.isDocumentPanelCollapsed {
                editorStore.toggleDocumentPanel()
            }
        }
        .overlay(alignment: .bottom) {
            if !editorStore.isDocumentPanelCollapsed {
                Rectangle()
                    .fill(StudioChrome.divider)
                    .frame(height: dividerHeight)
            }
        }
    }

    private var resizeGesture: some Gesture {
        DragGesture(minimumDistance: 3)
            .onChanged { value in
                isDraggingResizeHandle = true
                if dragStartHeight == nil {
                    dragStartHeight = editorStore.documentPanelHeight
                }

                let startHeight = dragStartHeight ?? editorStore.documentPanelHeight
                editorStore.setDocumentPanelHeight(startHeight - value.translation.height, maxHeight: maxPanelHeight)
            }
            .onEnded { _ in
                dragStartHeight = nil
                isDraggingResizeHandle = false
            }
    }
}
