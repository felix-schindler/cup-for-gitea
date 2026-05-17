//
//  FollowLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct OrgMembersLoader: View {
	private let org: String
	@State private var state = LoadState<[Components.Schemas.User]>.loading

	init(_ org: String) {
		self.org = org
	}

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.orgListMembers(path: .init(org: org)).ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
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
