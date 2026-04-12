//
//  MermaidStudioTemplates.swift
//  Meriq
//
//  Created by Admin on 11/04/26.
//
import Foundation

enum MermaidStudioTemplates {
    static let all: [DiagramTemplate] = [
        DiagramTemplate(
            id: UUID(uuidString: "8D70BBA1-B773-4932-9A8D-D0A081306301") ?? UUID(),
            title: "Flowchart",
            subtitle: "Classic app and process flows",
            symbolName: "arrow.triangle.branch",
            source: """
            flowchart LR
                A[Start] --> B{Design approved?}
                B -->|Yes| C[Implement]
                B -->|No| D[Revise]
                C --> E[Ship]
                D --> A
            """
        ),
        DiagramTemplate(
            id: UUID(uuidString: "86A4B0DD-7E31-4B01-B0E2-9CC43A18F34B") ?? UUID(),
            title: "Sequence Diagram",
            subtitle: "API and collaboration flows",
            symbolName: "point.3.connected.trianglepath.dotted",
            source: """
            sequenceDiagram
                participant User
                participant App
                participant API
                User->>App: Create diagram
                App->>API: Sync metadata
                API-->>App: Persisted
                App-->>User: Success state
            """
        ),
        DiagramTemplate(
            id: UUID(uuidString: "6935CA12-D744-4E71-9A54-FEBA11161C17") ?? UUID(),
            title: "Gantt Chart",
            subtitle: "Roadmaps and delivery planning",
            symbolName: "chart.bar.xaxis",
            source: """
            gantt
                title Product Launch
                dateFormat  YYYY-MM-DD
                section Foundation
                Architecture      :done, a1, 2026-04-01, 5d
                Implementation    :active, a2, 2026-04-06, 8d
                section Launch
                QA                :2026-04-14, 4d
                Release           :2026-04-18, 2d
            """
        )
    ]
}
