//
//  SettingsView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

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
		}.navigationTitle("Settings")
	}
}
