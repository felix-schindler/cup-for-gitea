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
		List {
			if let users {
				switch users {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no users", systemImage: Icons.users.rawValue)
					} else {
						ForEach(success, id: \.id) { user in
							SmallUserView(user)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading users", systemImage: Icons.users.rawValue)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Users")
	}
}
