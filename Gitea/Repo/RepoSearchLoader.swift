//
//  RepoSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

enum RepoContext: Hashable {
	case search
	case user(Int64?)
	case org(Int64)
	case teamRepos(teamId: Int64, org: String)

	var isSearchable: Bool {
		switch self {
		case .search, .user, .org: true
		case .teamRepos: false
		}
	}
}

struct RepoSearchLoader: View {
	let context: RepoContext
	let starredBy: Int64?

	@State private var search: String
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading
	@State private var paging = Paging()
	@State private var filters = RepoSearchFilters()
	@State private var showFilters = false
	@State private var resolvedUserID: Int64?

	private let defaultLimit = 7

	init(context: RepoContext = .search, search: String = "", starredBy: Int64? = nil, limitToTopic: Bool = false) {
		self.context = context
		self.starredBy = starredBy
		_search = State(initialValue: search)
		var initialFilters = RepoSearchFilters()
		if limitToTopic {
			initialFilters.topic = true
		}
		_filters = State(initialValue: initialFilters)
	}

	private var queryKey: String {
		switch context {
		case .search:
			"search|\(search)|\(starredBy?.description ?? "")|\(filters.taskKey)"
		case .user(let id):
			"user|\(id?.description ?? "")|\(search)|\(filters.taskKey)"
		case .org(let id):
			"org|\(id)|\(search)|\(filters.taskKey)"
		case .teamRepos(let teamId, _):
			"team|\(teamId)"
		}
	}

	private var navigationTitle: LocalizedStringResource {
		switch context {
		case .search:
			starredBy != nil ? "Starred Repositories" : "Search Repositories"
		case .user, .org, .teamRepos:
			"Repositories"
		}
	}

	private var icon: String { Icons.repositories.rawValue }

	private func loadNextPage(debounced: Bool = false, reset: Bool = false) async {
		if debounced {
			try? await Task.sleep(nanoseconds: 350_000_000)
			guard !Task.isCancelled else { return }
		}
		guard !paging.isLoading else { return }
		paging.isLoading = true
		defer { paging.isLoading = false }
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit, reset: reset) { page in
			try await loadRepos(page: page)
		}
	}

	private func resetAndLoad(debounced: Bool = false) async {
		guard !paging.isLoading else { return }
		paging.reset()
		await loadNextPage(debounced: debounced, reset: true)
	}

	private func loadRepos(page: Int) async throws -> [Components.Schemas.Repository] {
		switch context {
		case .teamRepos(let teamId, _):
			return try await Network.shared.client.orgListTeamRepos(
				path: .init(id: teamId),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json
		default:
			break
		}

		if resolvedUserID == nil {
			switch context {
			case .user(let id):
				if let id {
					resolvedUserID = id
				} else {
					resolvedUserID = try await Network.shared.client.userGetCurrent().ok.body.json.id
				}
			case .org(let id):
				resolvedUserID = id
			case .search:
				break
			default:
				break
			}
		}

		let limit = defaultLimit
		return try await Network.shared.client.repoSearch(
			.init(
				query: .init(
					q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
					topic: filters.topic ? true : nil,
					includeDesc: filters.includeDesc ? true : nil,
					uid: resolvedUserID,
					starredBy: starredBy,
					_private: filters.isPrivate == .all ? nil : filters.isPrivate == .private ? true : false,
					template: filters.template,
					archived: filters.archived,
					mode: filters.modeValue,
					exclusive: resolvedUserID != nil ? true : nil,
					sort: filters.sortValue,
					order: filters.order == .desc ? "desc" : nil,
					page: page,
					limit: limit
				))
		).ok.body.json.data ?? []
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading repositories",
			emptyText: "There are no repositories",
			icon: icon,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore,
			loadingMoreText: "Loading more repositories"
		) { repo in
			SmallRepoView(repo)
		}
		.modifier { view in
			if context.isSearchable {
				view.searchable(text: $search, prompt: Text("Search repositories"))
			} else {
				view
			}
		}
		.toolbar {
			if context.isSearchable {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Filters", systemImage: "line.3.horizontal.decrease") {
						HapticFeedback.play(.light)
						showFilters = true
					}
				}
			}
		}
		.sheet(isPresented: $showFilters) {
			RepoSearchFiltersSheet(filters: $filters)
		}
		.task(id: queryKey) {
			await resetAndLoad(debounced: context.isSearchable)
		}
		.navigationTitle(Text(navigationTitle))
	}
}
