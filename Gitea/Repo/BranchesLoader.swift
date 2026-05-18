//
//  BranchesLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import SwiftUI

struct BranchesLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<[Components.Schemas.Branch]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.repoListBranches(path: .init(owner: owner, repo: repo)).ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.name,
			loadingText: "Loading Branches",
			emptyText: "There are no branches",
			icon: Icons.code.rawValue,
			load: load
		) { branch in
			VStack(alignment: .leading) {
				HStack {
					Text(branch.name.emojized())
						.fontWeight(.medium)
					if branch.protected {
						Image(systemName: "lock")
							.foregroundStyle(.secondary)
					}

					Spacer()

					VStack(alignment: .trailing) {
						Text(branch.commit.timestamp.toString())
						Text(branch.commit.id.prefix(10))
							.monospaced()
					}.font(.footnote)
				}

				if branch.commit.message.isNotEmpty {
					Text(branch.commit.message.emojized())
						.foregroundStyle(.secondary)
				}
			}
		}
		.navigationTitle("Branches")
	}
}
