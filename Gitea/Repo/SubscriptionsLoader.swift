//
//  SubscriptionsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct SubscriptionsLoader: View {
	private let icon = Icons.starred.rawValue
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading
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
			try await Network.shared.client.userCurrentListSubscriptions(.init(query: .init(page: page, limit: defaultLimit))).ok.body.json
		}
	}

	var body: some View {
		List {
			Section {
				Label(
					"Gitea Web provides two tabs, \"Subscriptions\" and \"Watching\", however the REST API only returns watched repositories, not the subscription items.",
					systemImage: "exclamationmark.triangle"
				)
				.foregroundStyle(.foreground, .yellow)
			}
			switch state {
			case .loading:
				LoadingView("Loading watched repositories", systemImage: icon)
			case .loaded(let repos), .loadingMore(let repos), .failedMore(let repos, _):
				if repos.isEmpty {
					if case .failedMore(_, let error) = state {
						FailedView(error)
					} else {
						NoContentView("There are no watched repositories", systemImage: icon)
					}
				} else {
					ForEach(repos, id: \.id) { repo in
						SmallRepoView(repo)
							.onAppear {
								if repo.id == repos.last?.id, paging.hasMore {
									Task { await loadNextPage() }
								}
							}
					}
					if case .loadingMore = state {
						LoadingView("Loading more", systemImage: icon)
					} else if case .failedMore(_, let error) = state {
						FailedView(error)
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await resetAndLoad()
		}.refreshable {
			await resetAndLoad()
		}.navigationTitle("Subscriptions")
	}
}

#Preview {
	NavigationStack {
		SubscriptionsLoader()
	}
}
