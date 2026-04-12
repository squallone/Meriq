//
//  SidebarCategoryButton.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct SidebarCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let isExpanded: Bool
    let action: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hexString: category.colorHex ?? "#53C3B0").opacity(0.20))
                    Image(systemName: category.iconSystemName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hexString: category.colorHex ?? "#53C3B0"))
                }
                .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(StudioChrome.textPrimary)
                    Text("\(category.diagramCount) diagrams")
                        .font(.system(size: 11))
                        .foregroundStyle(StudioChrome.textSecondary)
                }

                Spacer()

                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(StudioChrome.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? StudioChrome.surfaceSelected.opacity(0.94) : StudioChrome.surfaceSecondary.opacity(0.68))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? StudioChrome.borderStrong : StudioChrome.borderSoft, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Edit Category", action: onEdit)
            Button("Delete Category", role: .destructive, action: onDelete)
        }
    }
}
