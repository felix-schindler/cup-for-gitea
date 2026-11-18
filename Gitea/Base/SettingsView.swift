//
//  SettingsView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import StoreKit
import SwiftUI

struct SettingsView: View {
	@AppStorage("appearance") var appearance: String = ""
	@AppStorage("markdownStyle") var markdownStyle = MarkdownStyle.rendered

	var body: some View {
		Form {
			Section {
				Picker("Appearance", systemImage: "circle.lefthalf.filled", selection: $appearance) {
					Text("System").tag("")
					Text("Light").tag("light")
					Text("Dark").tag("dark")
				}
			}

			Section {
				NavigationLink(destination: InstancesView()) {
					Label("Instances", systemImage: "server.rack")
				}

				NavigationLink(destination: CacheView()) {
					Label("Caches", systemImage: "internaldrive")
				}
			}

			Section("Markdown") {
				Picker("Rendering", selection: $markdownStyle) {
					Text("Raw").tag(MarkdownStyle.raw)
					Text("Rendered").tag(MarkdownStyle.rendered)
					Text("HTML").tag(MarkdownStyle.html)
				}

				Text(
					"Raw shows the Markdown source with syntax highlighting. Rendered formats it natively. HTML uses a web view, so raw HTML such as <details> blocks is shown."
				)
				.font(.footnote)
				.foregroundStyle(.secondary)
			}

			Section {
				NavigationLink(destination: FeedbackView()) {
					Label("Feedback", systemImage: "exclamationmark.bubble")
				}

				AppStoreReview()
			}

			Section {
				Link(destination: URL(string: "https://schindlerfelix.de/projects/cup/privacy")!) {
					Label("Privacy Policy", systemImage: "hand.raised")
				}

				Link(
					destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
				) {
					Label("Terms of Use (EULA)", systemImage: "doc.text")
				}

				Link(destination: URL(string: "https://github.com/felix-schindler/cup-for-gitea")!) {
					Label("Source Code on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
				}
			}
		}
		.navigationTitle("Settings")
	}
}

private struct AppStoreReview: View {
	@Environment(\.requestReview) private var requestReview

	var body: some View {
		Button("App Store Review", systemImage: "star") {
			requestReview()
		}
	}
}
