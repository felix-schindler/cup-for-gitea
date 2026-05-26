//
//  SettingsView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct SettingsView: View {
	@AppStorage("appearance") var appearance: String = ""

	var body: some View {
		Form {
			Section {
				Picker("Appearance", systemImage: "circle.lefthalf.filled", selection: $appearance) {
					Text("System").tag("")
					Text("Light").tag("light")
					Text("Dark").tag("dark")
				}

				NavigationLink(destination: InstancesView()) {
					Label("Instances", systemImage: "server.rack")
				}

				NavigationLink(destination: FeedbackView()) {
					Label("Feedback", systemImage: "exclamationmark.bubble")
				}
			}
		}.navigationTitle("Settings")
	}
}
