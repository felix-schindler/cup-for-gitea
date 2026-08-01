//
//  ActionsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 27.05.26.
//

import SwiftUI

struct ActionsLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<[Components.Schemas.ActionWorkflowRun]>.loading
	@State private var paging = Paging()
	@State private var showFilters = false
	@State private var filters = ActionsSearchFilters()

	private let defaultLimit = 7

	private var queryKey: String {
		"\(owner)/\(repo)|\(filters.taskKey)"
	}

	private func resetAndLoad() async {
		guard !paging.isLoading else { return }
		state = .loading
		paging.reset()
		await loadNextPage()
	}

	private func loadNextPage() async {
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit) { page in
			let response = try await Network.shared.client.getWorkflowRuns(
				path: .init(owner: owner, repo: repo),
				query: .init(
					event: filters.eventFilter,
					branch: filters.branchFilter,
					status: filters.status == .all ? nil : filters.status.rawValue,
					actor: filters.actorFilter,
					page: page,
					limit: defaultLimit
				)
			).ok.body.json
			return response.workflowRuns ?? []
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Actions",
			emptyText: "There are no workflow runs",
			icon: Icons.actions.rawValue,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore
		) { run in
			NavigationLink(destination: ActionView(run: run, owner: owner, repo: repo)) {
				SmallActionView(run)
			}
		}
		.task(id: queryKey) {
			await resetAndLoad()
		}
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Filters", systemImage: "line.3.horizontal.decrease") {
					showFilters = true
				}
			}
		}
		.sheet(isPresented: $showFilters) {
			ActionsSearchFiltersSheet(filters: $filters)
		}
		.navigationTitle("Actions")
	}
}
