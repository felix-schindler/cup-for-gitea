//
//  SettingsView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SkipKit
import SwiftUI

struct SettingsView: View {
	@AppStorage("counter") var counter = 1
	@Binding var appearance: String

	var body: some View {
		Form {
			Section {
				Picker("Appearance", selection: $appearance) {
					Text("System").tag("")
					Text("Light").tag("light")
					Text("Dark").tag("dark")
				}
			}

			Section {
				NavigationLink("Bill of Materials") {
					SBOMView(bundle: .module)
				}

				if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
					Button("Version \(version) (\(counter))") {
						counter += 1
					}.foregroundStyle(.foreground)
				}

				HStack {
					PlatformHeartView()
					Text("Powered by [Skip](https://skip.dev)")
				}
			}
		}.navigationTitle("Settings")
	}
}

/// A view that shows a blue heart on iOS and a green heart on Android.
struct PlatformHeartView: View {
	var body: some View {
		#if os(Android)
			ComposeView {
				HeartComposer()
			}
		#else
			Text(verbatim: "💙")
		#endif
	}
}

#if SKIP
	/// Use a ContentComposer to integrate Compose content. This code will be transpiled to Kotlin.
	struct HeartComposer: ContentComposer {
		@Composable func Compose(context: ComposeContext) {
			androidx.compose.material3.Text("💚", modifier: context.modifier)
		}
	}
#endif
