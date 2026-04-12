//
//  IconPickerView.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String

    private let columns = Array(repeating: GridItem(.flexible(minimum: 44), spacing: 12), count: 5)

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MermaidStudioSymbols.categories, id: \.self) { symbol in
                    Button {
                        selectedIcon = symbol
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selectedIcon == symbol ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
                            Image(systemName: symbol)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(selectedIcon == symbol ? Color.accentColor : Color.primary)
                        }
                        .frame(height: 54)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
