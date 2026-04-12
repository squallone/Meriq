//
//  StudioBanner.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import SwiftUI

struct StudioBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.red.opacity(0.14))
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.red.opacity(0.28), lineWidth: 1)
            )
            .foregroundStyle(Color.red)
    }
}
