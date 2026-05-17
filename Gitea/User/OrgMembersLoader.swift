//
//  FollowLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct OrgMembersLoader: View {
	private let org: String
	@State private var users: Result<[Components.Schemas.User], Error>? = nil

	init(_ org: String) {
		self.org = org
	}

	private func load() async {
		do {
			let members = try await Network.shared.client.orgListMembers(path: .init(org: org)).ok.body.json
			self.users = .success(members)
		} catch {
			self.users = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: users,
			id: \.id,
			loadingText: "Loading members",
			emptyText: "This organization has no members",
			icon: Icons.users.rawValue,
			load: load
		) { user in
			SmallUserView(user, avatarSize: .medium)
		}
		.navigationTitle("Members")
	}
}
