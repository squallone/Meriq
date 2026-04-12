//
//  SidebarScopeButton.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct SidebarScopeButton: View {
    let title: String
    let subtitle: String
    let symbolName: String
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(isSelected ? StudioChrome.textPrimary : StudioChrome.textSecondary)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(StudioChrome.textSecondary)
                }

                Spacer()

                if isExpanded {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(StudioChrome.textSecondary)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(StudioChrome.textTertiary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? StudioChrome.surfaceSelected.opacity(0.94) : StudioChrome.surfaceSecondary.opacity(0.72))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? StudioChrome.borderStrong : StudioChrome.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
