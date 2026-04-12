//
//  MermaidPreviewEditRequest.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidPreviewEditRequest: Codable, Equatable {
    let tokenID: String
    let newText: String
}
