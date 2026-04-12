//
//  PreviewToolOverlay.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct PreviewToolOverlay: View {
    let mode: PreviewToolMode

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Rectangle()
                .fill(StudioChrome.surfacePrimary.opacity(0.10))

            VStack(alignment: .leading, spacing: 8) {
                Label(mode.title, systemImage: mode.symbolName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(StudioChrome.textPrimary)

                Text(mode.instruction)
                    .font(.system(size: 11))
                    .foregroundStyle(StudioChrome.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(StudioChrome.panelFill.opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(StudioChrome.borderStrong, lineWidth: 1)
            )
            .padding(16)
        }
        .allowsHitTesting(false)
        .overlay(alignment: .bottomTrailing) {
            Text("Esc to cancel")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(StudioChrome.textTertiary)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
    }
}
