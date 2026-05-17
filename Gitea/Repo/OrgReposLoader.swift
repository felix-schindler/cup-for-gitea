//
//  OrgReposLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct OrgReposLoader: View {
	let org: String
	private let icon = Icons.repositories.rawValue
	@State private var repos: Result<[Components.Schemas.Repository], Error>?

	init(_ org: String) {
		self.org = org
	}

	private func load() async {
		do {
			let repos = try await Network.shared.client.orgListRepos(.init(path: .init(org: org))).ok.body.json
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
