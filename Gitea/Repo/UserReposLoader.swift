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
	@State private var repos: Result<[Components.Schemas.Repository], Error>?

	init(_ username: String? = nil) {
		self.username = username
	}

	private func load() async {
		do {
			var repos: [Components.Schemas.Repository]
			if let username {
				repos = try await Network.shared.client.userListRepos(path: .init(username: username)).ok.body.json
			} else {
				repos = try await Network.shared.client.userCurrentListRepos().ok.body.json
			}
			self.repos = .success(repos)
		} catch {
			print(error, error.localizedDescription)
			self.repos = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: repos,
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
