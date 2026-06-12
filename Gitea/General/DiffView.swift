import SwiftUI

private struct FileDiffSectionView: View {
	let file: FileDiff

	@Environment(\.colorScheme) private var colorScheme

	private var diffContent: String {
		file.lines.map { line in
			switch line.type {
			case .addition: "+" + line.content
			case .deletion: "-" + line.content
			case .context: " " + line.content
			case .hunkHeader, .fileHeader: line.content
			}
		}.joined(separator: "\n")
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 0) {
			HStack {
				Image(systemName: icon(for: file.status))
					.foregroundStyle(color(for: file.status))
				Text(file.fileName)
					.font(.system(.caption, design: .monospaced))
			}
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.frame(maxWidth: .infinity, alignment: .leading)
			.background(Color.secondary.opacity(0.1))

			CodeTextView(
				diffContent,
				language: "diff",
				colorScheme: colorScheme
			)
			.padding(.horizontal, 12)
			.padding(.vertical, 8)
			.frame(maxWidth: .infinity, alignment: .leading)
		}
		.background(Color(.systemBackground))
		.clipShape(.rect(cornerRadius: 8))
	}

	private func icon(for status: String) -> String {
		switch status {
		case "added": "plus.circle"
		case "deleted": "minus.circle"
		case "modified": "pencil.circle"
		case "renamed": "arrow.right.circle"
		default: "doc.circle"
		}
	}

	private func color(for status: String) -> Color {
		switch status {
		case "added": .green
		case "deleted": .red
		case "modified": .orange
		case "renamed": .blue
		default: .secondary
		}
	}
}

struct DiffView: View {
	let diffText: String

	private var files: [FileDiff] {
		DiffParser.parse(diffText)
	}

	var body: some View {
		Group {
			if files.isEmpty {
				NoContentView(
					"No changes",
					systemImage: "doc.text",
					description: "No diff content available"
				)
			} else {
				ScrollView {
					LazyVStack(spacing: 12) {
						ForEach(files) { file in
							FileDiffSectionView(file: file)
						}
					}
					.padding()
				}
			}
		}
	}
}

#Preview {
	DiffView(
		diffText: """
			diff --git a/Example.swift b/Example.swift
			index abc123..def456 100644
			--- a/Example.swift
			+++ b/Example.swift
			@@ -1,5 +1,8 @@
			 import Foundation
			+
			 func hello() {
			-    print("Hello, World!")
			+    print("Hello, Diff!")
			+    print("This is a new line")
			+    print("Another new line")
			 }
			""")
}
