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
	@State private var paging = Paging()

	private let defaultLimit = 7

	private func resetAndLoad() async {
		guard !paging.isLoading else { return }
		paging.reset()
		await loadNextPage(reset: true)
	}

	private func loadNextPage(reset: Bool = false) async {
		guard !paging.isLoading else { return }
		paging.isLoading = true
		defer { paging.isLoading = false }
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit, reset: reset) { page in
			try await Network.shared.client
				.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo), query: .init(page: page, limit: defaultLimit)))
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
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore
		) { milestone in
			MilestoneView(milestone, owner: owner, repo: repo)
		}
		.toolbar {
			NavigationLink(destination: NewMilestoneView(owner: owner, repo: repo)) {
				Label("New Milestone", systemImage: "plus")
			}
		}
		.navigationTitle("Milestones")
	}
}

#Preview {
	NavigationStack {
		MilestonesLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
