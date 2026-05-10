//
//  ProfileView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct UserLoader: View {
	private let username: String?

	init(username: String? = nil) {
		self.username = username
	}

	var body: some View {
		List {
			NoContentView("Profile", systemImage: Icons.users.rawValue)
		}.toolbar {
			if username == nil {
				NavigationLink(
					destination: SettingsView(),
					label: {
						Label("Settings", systemImage: Icons.settings.rawValue)
					})
			}
		}
	}
}
