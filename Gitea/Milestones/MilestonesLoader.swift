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

	@State private var results: Result<[Components.Schemas.Milestone], Error>?
	private let icon = Icons.milestones.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client
				.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
			self.results = .success(results)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: results,
			id: \.id,
			loadingText: "Loading Milestones",
			emptyText: "There are no milestones",
			icon: icon,
			load: load
		) { milestone in
			Text(milestone.title.emojized())
		}
		.navigationTitle("Milestones")
	}
}

#Preview {
	NavigationStack {
		MilestonesLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
