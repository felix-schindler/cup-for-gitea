//
//  UserOrgLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct UserOrgLoader: View {
	let username: String?
	@State private var results: Result<[Components.Schemas.Organization], Error>? = nil

	init(_ username: String? = nil) {
		self.username = username
	}

	func load() async {
		do {
			var orgs: [Components.Schemas.Organization]
			if let username {
				orgs = try await Network.shared.client.orgListUserOrgs(.init(path: .init(username: username))).ok.body.json
			} else {
				orgs = try await Network.shared.client.orgListCurrentUserOrgs().ok.body.json
			}
			self.results = .success(orgs)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: results,
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
