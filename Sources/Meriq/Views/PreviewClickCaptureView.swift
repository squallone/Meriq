//
//  PreviewClickCaptureView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import AppKit
import SwiftUI

struct PreviewClickCaptureView: NSViewRepresentable {
    let mode: PreviewToolMode
    let onPreviewClick: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPreviewClick: onPreviewClick)
    }

    func makeNSView(context: Context) -> PreviewCaptureNSView {
        let view = PreviewCaptureNSView()
        view.coordinator = context.coordinator
        return view
    }

    static func dismantleNSView(_ nsView: PreviewCaptureNSView, coordinator: Coordinator) {
        nsView.teardown()
    }

    func updateNSView(_ nsView: PreviewCaptureNSView, context: Context) {
        context.coordinator.onPreviewClick = onPreviewClick
        nsView.currentMode = mode
        nsView.needsLayout = true
    }

    final class Coordinator {
        var onPreviewClick: () -> Void

        init(onPreviewClick: @escaping () -> Void) {
            self.onPreviewClick = onPreviewClick
        }
    }
}
