//
//  DiffView.swift
//  Gitea
//
//  Created by Felix Schindler on xx.06.25.
//

import SwiftUI

struct DiffView: View {
	@Environment(\.colorScheme) private var colorScheme

	let diffText: String

	var body: some View {
		Group {
			if diffText.isEmpty {
				NoContentView(
					"No changes",
					systemImage: "doc.text",
					description: "No diff content available"
				)
			} else {
				ScrollView {
					CodeTextView(diffText, language: "diff", colorScheme: colorScheme)
						.font(.system(.caption, design: .monospaced))
						.textSelection(.enabled)
						.frame(maxWidth: .infinity, alignment: .leading)
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
