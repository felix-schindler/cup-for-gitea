//
//  ContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum ContentTab: String, Hashable {
	case home, settings
}

struct ContentView: View {
	@AppStorage("tab") var tab = ContentTab.home
	@AppStorage("appearance") var appearance = ""

	var body: some View {
		TabView(selection: $tab) {
			NavigationStack {
				HomeView()
			}
			.tabItem { Label("Home", systemImage: "house.fill") }
			.tag(ContentTab.home)

			NavigationStack {
				SettingsView(appearance: $appearance)
					.navigationTitle("Settings")
			}
			.tabItem { Label("Settings", systemImage: "gearshape.fill") }
			.tag(ContentTab.settings)
		}.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
	}
}
