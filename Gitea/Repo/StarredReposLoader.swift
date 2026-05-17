//
//  StarredReposLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct StarredReposLoader: View {
	let username: String?
	private let icon = Icons.starred.rawValue
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading

	init(_ username: String? = nil) {
		self.username = username
	}

	private func load() async {
		state = await LoadState {
			if let username {
				try await Network.shared.client.userListStarred(path: .init(username: username)).ok.body.json
			} else {
				try await Network.shared.client.userCurrentListStarred().ok.body.json
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading starred Repositories",
			emptyText: "There are no starred repositories",
			icon: icon,
			load: load
		) { repo in
			SmallRepoView(repo)
		}
		.navigationTitle("Starred Repositories")
	}
}
