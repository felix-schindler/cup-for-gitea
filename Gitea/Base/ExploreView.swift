//
//  ExploreView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct ExploreView: View {
	var body: some View {
		List {
			NoContentView("Explore", systemImage: Icons.explore.rawValue)

			Section {
				Label("Repositories", systemImage: Icons.repositories.rawValue)
				Label("Users", systemImage: Icons.users.rawValue)
				Label("Organizations", systemImage: Icons.organizations.rawValue)
			}
		}
	}
}
