//
//  MermaidPreviewPalette.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidPreviewPalette: Codable, Equatable {
    let pageStartColor: String
    let pageEndColor: String
    let glowColorOne: String
    let glowColorTwo: String
    let pageTextColor: String
    let canvasBackground: String
    let canvasBorderColor: String
    let canvasShadowColor: String
    let captionBackground: String
    let captionTextColor: String
    let errorBackground: String
    let errorBorderColor: String
    let errorTextColor: String
    let placeholderBackground: String
    let placeholderBorderColor: String
    let placeholderTextColor: String
}
