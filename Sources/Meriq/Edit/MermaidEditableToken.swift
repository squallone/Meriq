//
//  MermaidEditableToken.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidEditableToken: Identifiable, Codable, Equatable {
    let id: String
    let kind: MermaidEditableTokenKind
    let line: Int
    let utf16Offset: Int
    let utf16Length: Int
    let text: String
    let normalizedText: String
    let sourceIdentifier: String?
    let closingDelimiter: String
}
