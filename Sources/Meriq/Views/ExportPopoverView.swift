//
//  ExportPopoverView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct ExportPopoverView: View {
    @EnvironmentObject private var editorStore: EditorStore

    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Configure output for the selected diagram.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if editorStore.draft != nil {
                exportGroup("Format") {
                    Picker("Format", selection: $editorStore.exportConfiguration.variant) {
                        ForEach(MermaidExportVariant.allCases) { variant in
                            Text(variant.title).tag(variant)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                exportGroup("Output Size") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Scale")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(Int(editorStore.exportConfiguration.scale * 100))%")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }

                        Slider(value: $editorStore.exportConfiguration.scale, in: 1.0...4.0, step: 0.5)

                        HStack {
                            Text("100%")
                            Spacer()
                            Text("400%")
                        }
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    Button("Copy \(editorStore.exportConfiguration.variant.title)") {
                        editorStore.renderer.copyToClipboard(
                            variant: editorStore.exportConfiguration.variant,
                            scale: editorStore.exportConfiguration.scale
                        )
                        isPresented = false
                    }
                    .buttonStyle(.bordered)

                    Button("Export \(editorStore.exportConfiguration.variant.title)") {
                        editorStore.renderer.exportToFile(
                            variant: editorStore.exportConfiguration.variant,
                            scale: editorStore.exportConfiguration.scale
                        )
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Text("Select a diagram to configure export.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(width: 340)
    }

    private func exportGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
            content()
        }
    }
}
