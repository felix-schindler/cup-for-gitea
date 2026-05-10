//
//  CodeTextView.swift
//  Tanuki
//
//  Created by Felix Schindler on 07.04.24.
//

import Highlightr
import SwiftUI

/// Inspiration from: https://github.com/mortenjust/CodeHighlighter
/// See: https://highlightjs.org and https://github.com/raspu/Highlightr
public struct CodeTextView: View {
	private var highlightedCode: AttributedString

	public init(
		_ code: String,
		language: String,
		colorScheme: ColorScheme,
		lightTheme: String = "vs",
		darkTheme: String = "vs2015",
		fontSize: Double = 12
	) {
		if let highlighter = Highlightr() {
			let lang = language.lowercased()
			if !highlighter.supportedLanguages().contains(lang) {
				print("WARNING: Language \(lang) isn't supported, using auto detect")
			}

			let theme = colorScheme == .dark ? darkTheme : lightTheme
			if highlighter.availableThemes().contains(theme) {
				highlighter.setTheme(to: theme)
			} else {
				print("WARNING: Theme \(theme) isn't supported")
			}

			if let nsAtrStr = highlighter.highlight(code, as: lang) {
				highlightedCode = AttributedString(nsAtrStr)
			} else {
				highlightedCode = AttributedString(code)
			}
		} else {
			highlightedCode = AttributedString(code)
		}

		highlightedCode.font = .custom("SF Mono", size: fontSize)
		highlightedCode.inlinePresentationIntent = .code
	}

	public var body: some View {
		Text(highlightedCode)
			.lineSpacing(4)
			.textSelection(.enabled)
	}
}

#Preview {
	CodeTextView(
		"let a = 2;\nconsole.log('Test', a);\n\nfor (const b of c) {\n\tconsole.log(b);\n}\n",
		language: "javascript",
		colorScheme: .light,
		fontSize: 24
	)
}
