//
//  PreviewDetailColumn.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct PreviewDetailColumn: View {
    @EnvironmentObject private var editorStore: EditorStore

    var body: some View {
        GeometryReader { proxy in
            let maxPanelHeight = min(420.0, max(220.0, proxy.size.height * 0.48))

            VStack(spacing: 12) {
                MermaidPreviewPane()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                DocumentBottomPanel(maxPanelHeight: maxPanelHeight)
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
