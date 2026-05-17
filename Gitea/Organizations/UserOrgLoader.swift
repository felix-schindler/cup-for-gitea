//
//  UserOrgLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct UserOrgLoader: View {
	let username: String?
	@State private var state = LoadState<[Components.Schemas.Organization]>.loading

	init(_ username: String? = nil) {
		self.username = username
	}

	func load() async {
		state = await LoadState {
			if let username {
				try await Network.shared.client.orgListUserOrgs(.init(path: .init(username: username))).ok.body.json
			} else {
				try await Network.shared.client.orgListCurrentUserOrgs().ok.body.json
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading organizations",
			emptyText: "There are no organizations",
			icon: Icons.organizations.rawValue,
			load: load
		) { org in
			SmallOrgView(org)
		}
		.navigationTitle("Organizations")
	}
}

#Preview {
	NavigationStack {
		UserOrgLoader("felix-schindler")
	}
}
