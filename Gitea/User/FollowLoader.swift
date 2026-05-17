//
//  FollowLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

enum UsersType {
	case followers, following
}

struct FollowLoader: View {
	private let username: String
	private let filterUserType: UsersType
	@State private var state = LoadState<[Components.Schemas.User]>.loading

	init(_ username: String, type: UsersType) {
		self.username = username
		self.filterUserType = type
	}

	private func load() async {
		state = await LoadState {
			switch filterUserType {
			case .followers:
				try await Network.shared.client.userListFollowers(path: .init(username: username)).ok.body.json
			case .following:
				try await Network.shared.client.userListFollowing(path: .init(username: username)).ok.body.json
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading users",
			emptyText: "There are no users",
			icon: Icons.users.rawValue,
			load: load
		) { user in
			SmallUserView(user, avatarSize: .medium)
		}
		.navigationTitle("Users")
	}
}
