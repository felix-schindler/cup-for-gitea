//
//  Markdown.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import MarkdownView
import SwiftUI
import Textual

enum MarkdownStyle: String {
	case raw,
		rendered,
		html
}

/// Renders markdown the way it is configured in Settings.
struct Markdown: View {
	@Environment(\.colorScheme) private var colorScheme
	@AppStorage("markdownStyle") private var style = MarkdownStyle.rendered

	private let content: String

	init(_ content: String) {
		self.content = content.emojized()
	}

	var body: some View {
		switch style {
		case .raw:
			CodeTextView(content, language: "markdown", colorScheme: colorScheme)
		case .rendered:
			StructuredText(markdown: content)
				.textual.structuredTextStyle(.gitHub)
				.textual.textSelection(.enabled)
		case .html:
			HTMLMarkdown(content)
		}
	}
}

private struct HTMLMarkdown: View {
	private let content: String

	@State
	private var height: CGFloat = 1

	init(_ content: String) {
		self.content = content
	}

	private static let compactCSS =
		"body{margin:0 !important;padding:0 !important;}"
		+ ".container{padding-left:0 !important;padding-right:0 !important;}"
		+ "#contents>:first-child{margin-top:0 !important;}"
		+ "#contents>:last-child{margin-bottom:0 !important;}"

	var body: some View {
		MarkdownUI(body: content, css: Self.compactCSS, styled: true)
			.onRendered { renderedHeight in
				if renderedHeight > 0, abs(renderedHeight - height) > 1 {
					height = renderedHeight
				}
			}
			.frame(maxWidth: .infinity)
			.frame(height: height)
	}
}
