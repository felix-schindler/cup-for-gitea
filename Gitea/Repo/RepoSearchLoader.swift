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
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var isLoadingMore = false
	@State private var filters = RepoSearchFilters()
	@State private var showFilters = false
	@State private var resolvedUserID: Int64?

	private let debounceNanoseconds: UInt64 = 350_000_000
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

	private func loadNextPage(debounced: Bool = false) async {
		guard !isLoadingMore, hasMorePages else { return }
		isLoadingMore = true
		defer { isLoadingMore = false }
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		let currentItems: [Components.Schemas.Repository]
		if case .loaded(let items) = state {
			currentItems = items
			state = .loadingMore(items)
		} else {
			currentItems = []
		}
		do {
			let page = try await loadRepos()
			if Task.isCancelled { return }
			state = .loaded(currentItems + page)
			let limit = filters.limitValue ?? defaultLimit
			if page.count < limit {
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

	private func resetAndLoad(debounced: Bool = false) async {
		guard !isLoadingMore else { return }
		state = .loading
		currentPage = 1
		hasMorePages = true
		await loadNextPage(debounced: debounced)
	}

	private func loadRepos() async throws -> [Components.Schemas.Repository] {
		switch context {
		case .teamRepos(let teamId, _):
			return try await Network.shared.client.orgListTeamRepos(
				path: .init(id: teamId),
				query: .init(page: currentPage, limit: defaultLimit)
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

		let limit = filters.limitValue ?? defaultLimit
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
					page: currentPage,
					limit: limit
				))
		).ok.body.json.data
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
			hasMorePages: hasMorePages,
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
			NavigationStack {
				RepoSearchFiltersSheet(filters: $filters)
			}
		}
		.task(id: queryKey) {
			await resetAndLoad(debounced: context.isSearchable)
		}
		.onChange(of: state) { oldState, newState in
			if case .loading = oldState, case .loaded(let items) = newState, search.isEmpty {
				Task { try? await SpotlightIndexer.index(repos: items) }
			}
		}
		.navigationTitle(Text(navigationTitle))
	}
}
