//
//  ContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum ContentTab: String, Hashable {
	case home, profile, search
}

struct ContentView: View {
	@AppStorage("tab") var tab = ContentTab.home
	@AppStorage("appearance") var appearance = ""
	@StateObject private var sessionStore = SessionStore.shared

	var body: some View {
		Group {
			TabView(selection: $tab) {
				Tab("Home", systemImage: Icons.home.rawValue, value: ContentTab.home) {
					NavigationStack {
						HomeView()
					}
				}

				Tab("Profile", systemImage: Icons.users.rawValue, value: ContentTab.profile) {
					NavigationStack {
						UserLoader()
					}
				}

				Tab(value: ContentTab.search, role: .search) {
					NavigationStack {
						SearchView()
					}
				}
			}
		}.task {
			sessionStore.refresh()
		}.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
	}
}
