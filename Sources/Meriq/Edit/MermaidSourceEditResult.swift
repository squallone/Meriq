//
//  MermaidSourceEditResult.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

struct MermaidSourceEditResult: Equatable {
    let updatedSource: String
    let editedToken: MermaidEditableToken
}
