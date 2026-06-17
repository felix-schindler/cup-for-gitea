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
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var isLoadingMore = false
	@State private var showFilters = false
	@State private var filters = ActionsSearchFilters()

	private let defaultLimit = 7

	private var queryKey: String {
		"\(owner)/\(repo)|\(filters.taskKey)"
	}

	private func resetAndLoad() async {
		guard !isLoadingMore else { return }
		state = .loading
		currentPage = 1
		hasMorePages = true
		await loadNextPage()
	}

	private func loadNextPage() async {
		guard !isLoadingMore, hasMorePages else { return }
		isLoadingMore = true
		defer { isLoadingMore = false }
		let currentItems: [Components.Schemas.ActionWorkflowRun]
		if case .loaded(let items) = state {
			currentItems = items
			state = .loadingMore(items)
		} else {
			currentItems = []
		}
		do {
			let response = try await Network.shared.client.getWorkflowRuns(
				path: .init(owner: owner, repo: repo),
				query: .init(
					event: filters.eventFilter,
					branch: filters.branchFilter,
					status: filters.status == .all ? nil : filters.status.rawValue,
					actor: filters.actorFilter,
					page: currentPage,
					limit: defaultLimit
				)
			).ok.body.json
			if Task.isCancelled { return }
			state = .loaded(currentItems + response.workflowRuns)
			if response.workflowRuns.count < defaultLimit {
				hasMorePages = false
			} else {
				currentPage += 1
			}
		} catch {
			if Task.isCancelled { return }
			if currentItems.isEmpty {
				state = .failed(error)
			} else {
				state = .failedMore(currentItems, error)
			}
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
			hasMorePages: hasMorePages
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
			NavigationStack {
				ActionsSearchFiltersSheet(filters: $filters)
			}
		}
		.navigationTitle("Actions")
	}
}
