//
//  CategoryEditorSheet.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct CategoryEditorSheet: View {
    @EnvironmentObject private var libraryStore: LibraryStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(libraryStore.categoryDraft.id == nil ? "New Category" : "Edit Category")
                .font(.system(size: 22, weight: .semibold))

            TextField("Category Name", text: $libraryStore.categoryDraft.name)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 12) {
                Text("Icon")
                    .font(.system(size: 13, weight: .semibold))
                IconPickerView(selectedIcon: $libraryStore.categoryDraft.iconSystemName)
            }

            HStack {
                Text("Tint")
                    .font(.system(size: 13, weight: .semibold))
                ColorPicker("", selection: Binding(
                    get: { Color(hexString: libraryStore.categoryDraft.colorHex) },
                    set: { libraryStore.categoryDraft.colorHex = $0.hexRGBString }
                ), supportsOpacity: false)
                .labelsHidden()
                Text(libraryStore.categoryDraft.colorHex)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Save Category") {
                    libraryStore.saveCategoryDraft()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 520, height: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
