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
		List {
			if let users {
				switch users {
				case .success(let success):
					if success.isEmpty {
						NoContentView("This organization has no members", systemImage: Icons.users.rawValue)
					} else {
						ForEach(success, id: \.id) { user in
							SmallUserView(user)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading members", systemImage: Icons.users.rawValue)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Members")
	}
}
