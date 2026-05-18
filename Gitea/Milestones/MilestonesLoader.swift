//
//  MilestonesLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct MilestonesLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<[Components.Schemas.Milestone]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Milestones",
			emptyText: "There are no milestones",
			icon: Icons.milestones.rawValue,
			load: load
		) { milestone in
			MilestoneView(milestone, owner: owner, repo: repo)
		}
		.navigationTitle("Milestones")
	}
}

#Preview {
	NavigationStack {
		MilestonesLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
