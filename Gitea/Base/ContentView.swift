//
//  ContentView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum ContentTab: String, Hashable {
	case home, activity, profile, search
}

enum PadTab: String, CaseIterable {
	case home, search, activity, profile, settings
}

struct ContentView: View {
	@AppStorage("tab") var tab = ContentTab.home
	@AppStorage("padTab") var padTab: PadTab?
	@AppStorage("appearance") var appearance = ""
	@StateObject private var sessionStore = SessionStore.shared
	@State private var showSettings = false

	var body: some View {
		Group {
			if UIDevice.current.userInterfaceIdiom == .pad {
				ipadBody
			} else {
				iphoneBody
			}
		}.task {
			sessionStore.refresh()
		}.preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
	}

	@ViewBuilder
	private var ipadBody: some View {
		NavigationSplitView {
			sidebar
		} detail: {
			if let padTab {
				NavigationStack {
					content(for: padTab)
				}
			} else {
				VStack {
					if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
						let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
						let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
						let lastIcon = iconFiles.last,
						let iconImage = UIImage(named: lastIcon)
					{
						Image(uiImage: iconImage)
							.resizable()
							.scaledToFit()
							.cornerRadius(15)
							.frame(maxWidth: 70, maxHeight: 70)
					}

					Text("Welcome to Cup")
						.font(.title2)
						.fontWeight(.bold)
						.multilineTextAlignment(.center)
				}
			}
		}
	}

	@ViewBuilder
	private var iphoneBody: some View {
		TabView(selection: $tab) {
			Tab("Home", systemImage: Icons.home.rawValue, value: ContentTab.home) {
				NavigationStack { HomeView() }
			}

			Tab("Activity", systemImage: Icons.activity.rawValue, value: ContentTab.activity) {
				NavigationStack { ActivityLoader(context: .home) }
			}

			Tab("Profile", systemImage: Icons.users.rawValue, value: ContentTab.profile) {
				NavigationStack { UserLoader() }
			}

			Tab(value: ContentTab.search, role: .search) {
				NavigationStack { SearchView() }
			}
		}
	}

	@ViewBuilder
	private var sidebar: some View {
		List(selection: $padTab) {
			Label("Home", systemImage: Icons.home.rawValue)
				.tag(PadTab.home)
			Label("Activity", systemImage: Icons.activity.rawValue)
				.tag(PadTab.activity)
			Label("Search", systemImage: Icons.search.rawValue)
				.tag(PadTab.search)
			Label("Profile", systemImage: Icons.users.rawValue)
				.tag(PadTab.profile)
			Label("Settings", systemImage: Icons.settings.rawValue)
				.tag(PadTab.settings)
		}.listStyle(.sidebar)
	}

	@ViewBuilder
	private func content(for tab: PadTab) -> some View {
		switch tab {
		case .home:
			HomeView()
		case .activity:
			ActivityLoader(context: .home)
		case .profile:
			UserLoader()
		case .search:
			SearchView()
		case .settings:
			SettingsView()
		}
	}
}
