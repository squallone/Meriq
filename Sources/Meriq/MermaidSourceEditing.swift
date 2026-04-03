import Foundation

enum MermaidEditableTokenKind: String, Codable, Equatable {
    case nodeLabel
    case edgeLabel
}

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

struct MermaidPreviewEditRequest: Codable, Equatable {
    let tokenID: String
    let newText: String
}

struct MermaidSourceEditResult: Equatable {
    let updatedSource: String
    let editedToken: MermaidEditableToken
}

struct MermaidSourceEditingEngine {
    func editableTokens(in source: String) -> [MermaidEditableToken] {
        guard isFlowchart(source) else { return [] }
        return parseFlowchartTokens(source: source)
    }

    func applyPreviewEdit(_ request: MermaidPreviewEditRequest, to source: String) throws -> MermaidSourceEditResult {
        let tokens = editableTokens(in: source)

        guard let token = tokens.first(where: { $0.id == request.tokenID }) else {
            throw NSError(
                domain: "Meriq.SourceEditing",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not find the selected diagram label in the Mermaid source."]
            )
        }

        let sanitizedText = sanitizedReplacementText(request.newText, for: token)
        let sourceRange = try utf16Range(
            location: token.utf16Offset,
            length: token.utf16Length,
            in: source
        )

        var updatedSource = source
        updatedSource.replaceSubrange(sourceRange, with: sanitizedText)

        return MermaidSourceEditResult(
            updatedSource: updatedSource,
            editedToken: token
        )
    }

    private func isFlowchart(_ source: String) -> Bool {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("flowchart") || trimmed.hasPrefix("graph")
    }

    private func parseFlowchartTokens(source: String) -> [MermaidEditableToken] {
        let lines = source.components(separatedBy: "\n")
        var tokens: [MermaidEditableToken] = []
        var runningUTF16Offset = 0

        for (lineIndex, line) in lines.enumerated() {
            let lineNumber = lineIndex + 1
            tokens.append(contentsOf: parseFlowchartLine(line, lineNumber: lineNumber, baseOffset: runningUTF16Offset))
            runningUTF16Offset += line.utf16.count
            if lineIndex < lines.count - 1 {
                runningUTF16Offset += 1
            }
        }

        return tokens
    }

    private func parseFlowchartLine(_ line: String, lineNumber: Int, baseOffset: Int) -> [MermaidEditableToken] {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("%%") || skippedFlowchartDirective(line: trimmed) {
            return []
        }

        var tokens: [MermaidEditableToken] = []
        tokens.append(contentsOf: parseNodeTokens(in: line, lineNumber: lineNumber, baseOffset: baseOffset))
        tokens.append(contentsOf: parseEdgeTokens(in: line, lineNumber: lineNumber, baseOffset: baseOffset))
        return tokens
    }

    private func skippedFlowchartDirective(line: String) -> Bool {
        let directives = ["subgraph", "end", "click ", "style ", "classDef", "class ", "linkStyle"]
        return directives.contains { line.hasPrefix($0) }
    }

    private func parseNodeTokens(in line: String, lineNumber: Int, baseOffset: Int) -> [MermaidEditableToken] {
        let openClosePairs: [(open: String, close: String)] = [
            ("[[", "]]"),
            ("((", "))"),
            ("[", "]"),
            ("(", ")"),
            ("{", "}")
        ]

        let characters = Array(line)
        var tokens: [MermaidEditableToken] = []
        var nodeOccurrence = 0
        var index = 0

        while index < characters.count {
            guard isIdentifierStart(characters[index]) else {
                index += 1
                continue
            }

            let identifierStart = index
            index += 1
            while index < characters.count, isIdentifierBody(characters[index]) {
                index += 1
            }

            let identifier = String(characters[identifierStart..<index])
            if identifier.lowercased() == "graph" || identifier.lowercased() == "flowchart" {
                continue
            }

            var cursor = index
            while cursor < characters.count, characters[cursor].isWhitespace {
                cursor += 1
            }

            guard let pair = openClosePairs.first(where: {
                cursor + $0.open.count <= characters.count &&
                String(characters[cursor..<(cursor + $0.open.count)]) == $0.open
            }) else {
                index = cursor
                continue
            }

            let contentStart = cursor + pair.open.count
            guard let contentEnd = findClosing(pair.close, in: characters, startingAt: contentStart) else {
                index = cursor + pair.open.count
                continue
            }

            let label = String(characters[contentStart..<contentEnd])
            if !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let offset = baseOffset + utf16Offset(in: line, characterOffset: contentStart)
                let length = label.utf16.count
                nodeOccurrence += 1
                tokens.append(
                    MermaidEditableToken(
                        id: "flowchart-node-\(lineNumber)-\(nodeOccurrence)-\(identifier)",
                        kind: .nodeLabel,
                        line: lineNumber,
                        utf16Offset: offset,
                        utf16Length: length,
                        text: label,
                        normalizedText: normalized(label),
                        sourceIdentifier: identifier,
                        closingDelimiter: pair.close
                    )
                )
            }

            index = contentEnd + pair.close.count
        }

        return tokens
    }

    private func parseEdgeTokens(in line: String, lineNumber: Int, baseOffset: Int) -> [MermaidEditableToken] {
        let pattern = #"\|([^|\n]+)\|"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        var tokens: [MermaidEditableToken] = []

        for (index, match) in matches.enumerated() {
            guard match.numberOfRanges > 1 else { continue }
            let range = match.range(at: 1)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: line) else { continue }
            let label = String(line[swiftRange])
            let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            tokens.append(
                MermaidEditableToken(
                    id: "flowchart-edge-\(lineNumber)-\(index + 1)",
                    kind: .edgeLabel,
                    line: lineNumber,
                    utf16Offset: baseOffset + range.location,
                    utf16Length: range.length,
                    text: label,
                    normalizedText: normalized(label),
                    sourceIdentifier: nil,
                    closingDelimiter: "|"
                )
            )
        }

        return tokens
    }

    private func findClosing(_ delimiter: String, in characters: [Character], startingAt start: Int) -> Int? {
        guard !delimiter.isEmpty else { return nil }
        let delimiterCount = delimiter.count
        guard start <= characters.count - delimiterCount else { return nil }

        var index = start
        while index <= characters.count - delimiterCount {
            if String(characters[index..<(index + delimiterCount)]) == delimiter {
                return index
            }
            index += 1
        }

        return nil
    }

    private func utf16Offset(in line: String, characterOffset: Int) -> Int {
        let endIndex = line.index(line.startIndex, offsetBy: characterOffset)
        return line[..<endIndex].utf16.count
    }

    private func utf16Range(location: Int, length: Int, in source: String) throws -> Range<String.Index> {
        let utf16View = source.utf16
        guard location >= 0, length >= 0, location + length <= utf16View.count else {
            throw NSError(
                domain: "Meriq.SourceEditing",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not translate the selected preview label back into Mermaid source positions."]
            )
        }

        let utf16Start = utf16View.index(utf16View.startIndex, offsetBy: location)
        let utf16End = utf16View.index(utf16View.startIndex, offsetBy: location + length)

        guard
            let start = String.Index(utf16Start, within: source),
            let end = String.Index(utf16End, within: source)
        else {
            throw NSError(
                domain: "Meriq.SourceEditing",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Could not translate the selected preview label back into Mermaid source positions."]
            )
        }

        return start..<end
    }

    private func sanitizedReplacementText(_ text: String, for token: MermaidEditableToken) -> String {
        let collapsedWhitespace = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let fallback = collapsedWhitespace.isEmpty ? token.text : collapsedWhitespace
        switch token.kind {
        case .edgeLabel:
            return fallback.replacingOccurrences(of: "|", with: "/")
        case .nodeLabel:
            let unsafeDelimiters = [token.closingDelimiter, "[", "]", "{", "}", "(", ")"]
            return unsafeDelimiters.reduce(fallback) { partialResult, delimiter in
                partialResult.replacingOccurrences(of: delimiter, with: " ")
            }
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private func normalized(_ text: String) -> String {
        text
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func isIdentifierStart(_ character: Character) -> Bool {
        character.isLetter || character == "_"
    }

    private func isIdentifierBody(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || character == "_" || character == "-" || character == "."
    }
}
