//
//  ProfileView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct CurrentUserLoader: View {
	@Binding var appearance: String

	var body: some View {
		List {
			NoContentView("Profile", systemImage: Icons.users.rawValue)
		}.toolbar {
			NavigationLink(
				destination: SettingsView(appearance: $appearance),
				label: {
					Label("Settings", systemImage: Icons.settings.rawValue)
				})
		}
	}
}
