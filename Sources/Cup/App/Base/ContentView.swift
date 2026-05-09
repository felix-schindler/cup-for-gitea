//
//  ContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum ContentTab: String, Hashable {
	case home, explore, profile, search
}

struct ContentView: View {
	@AppStorage("tab") var tab = ContentTab.home
	@AppStorage("appearance") var appearance = ""

	var body: some View {
		Group {
			if #available(iOS 26.0, *) {
				TabView(selection: $tab) {
					Tab("Home", systemImage: Icons.home.rawValue, value: ContentTab.home) {
						NavigationStack {
							HomeView()
						}
					}

					Tab("Explore", systemImage: Icons.explore.rawValue, value: ContentTab.explore) {
						NavigationStack {
							ExploreView()
						}
					}

					Tab("Profile", systemImage: Icons.users.rawValue, value: ContentTab.profile) {
						NavigationStack {
							CurrentUserLoader(appearance: $appearance)
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
					.tabItem { Label("Home", systemImage: Icons.home.rawValue) }
					.tag(ContentTab.home)

					NavigationStack {
						ExploreView()
					}
					.tabItem { Label("Explore", systemImage: Icons.explore.rawValue) }
					.tag(ContentTab.explore)

					NavigationStack {
						SearchView()
					}
					.tabItem { Label("Search", systemImage: Icons.search.rawValue) }
					.tag(ContentTab.search)

					NavigationStack {
						CurrentUserLoader(appearance: $appearance)
					}
					.tabItem { Label("Profile", systemImage: Icons.users.rawValue) }
					.tag(ContentTab.profile)
				}
			}
		}.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
	}
}
