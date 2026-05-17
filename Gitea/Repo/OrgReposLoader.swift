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
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading

	init(_ org: String) {
		self.org = org
	}

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.orgListRepos(.init(path: .init(org: org))).ok.body.json
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
