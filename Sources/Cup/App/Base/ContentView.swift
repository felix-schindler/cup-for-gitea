//
//  ContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum ContentTab: String, Hashable {
	case home, profile, settings, search
}

struct ContentView: View {
	@AppStorage("tab") var tab = ContentTab.home
	@AppStorage("appearance") var appearance = ""

	var body: some View {
		Group {
			if #available(iOS 26.0, *) {
				TabView(selection: $tab) {
					Tab("Home", systemImage: "house.fill", value: ContentTab.home) {
						NavigationStack {
							HomeView()
						}
					}

					Tab("Profile", systemImage: "person.fill", value: ContentTab.profile) {
						NavigationStack {
							Text("Profile")
						}
					}

					Tab("Settings", systemImage: "gearshape.fill", value: ContentTab.settings) {
						NavigationStack {
							SettingsView(appearance: $appearance)
						}
					}

					Tab(value: ContentTab.search, role: .search) {
						NavigationStack {
							SearchView()
						}
					}
				}
			} else {
				TabView(selection: $tab) {
					NavigationStack {
						HomeView()
					}
					.tabItem { Label("Home", systemImage: "house.fill") }
					.tag(ContentTab.home)

					NavigationStack {
						SearchView()
					}
					.tabItem { Label("Search", systemImage: "magnifyingglass") }
					.tag(ContentTab.search)

					NavigationStack {
						Text("Profile")
					}
					.tabItem { Label("Profile", systemImage: "person.fill") }
					.tag(ContentTab.profile)

					NavigationStack {
						SettingsView(appearance: $appearance)
					}
					.tabItem { Label("Settings", systemImage: "gearshape.fill") }
					.tag(ContentTab.settings)
				}
			}
		}.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
	}
}
