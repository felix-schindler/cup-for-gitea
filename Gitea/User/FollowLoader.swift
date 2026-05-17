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
	@State private var users: Result<[Components.Schemas.User], Error>? = nil

	init(_ username: String, type: UsersType) {
		self.username = username
		self.filterUserType = type
	}

	private func load() async {
		do {
			var users: [Components.Schemas.User]
			switch filterUserType {
			case .followers:
				users = try await Network.shared.client.userListFollowers(path: .init(username: username)).ok.body.json
			case .following:
				users = try await Network.shared.client.userListFollowing(path: .init(username: username)).ok.body.json
			}
			self.users = .success(users)
		} catch {
			self.users = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: users,
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
