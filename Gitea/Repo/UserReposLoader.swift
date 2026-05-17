//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct UserReposLoader: View {
	let username: String?
	private let icon = Icons.repositories.rawValue
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading

	init(_ username: String? = nil) {
		self.username = username
	}

	private func load() async {
		state = await LoadState {
			if let username {
				try await Network.shared.client.userListRepos(path: .init(username: username)).ok.body.json
			} else {
				try await Network.shared.client.userCurrentListRepos().ok.body.json
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Repositories",
			emptyText: "There are no Repositories",
			icon: icon,
			load: load
		) { repo in
			SmallRepoView(repo)
		}
		.navigationTitle("Repositories")
	}
}
