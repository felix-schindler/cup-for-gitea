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
		List {
			if let results {
				switch results {
				case .success(let success):
					ForEach(success, id: \.id) { org in
						SmallOrgView(org)
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading organizations", systemImage: Icons.organizations.rawValue)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Organizations")
	}
}

#Preview {
	NavigationStack {
		UserOrgLoader("felix-schindler")
	}
}
