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
	@State private var results: [Components.Schemas.Repository] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var filters = RepoSearchFilters()
	@State private var showFilters = false
	@State private var resolvedUserID: Int64?

	private let debounceNanoseconds: UInt64 = 350_000_000
	private let defaultLimit = 20

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
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			let page = try await loadRepos()
			if Task.isCancelled { return }
			if page.isEmpty {
				hasMorePages = false
			} else {
				results.append(contentsOf: page)
				let limit = filters.limitValue ?? defaultLimit
				if page.count < limit {
					hasMorePages = false
				} else {
					currentPage += 1
				}
			}
		} catch {
			if Task.isCancelled { return }
			self.error = error
		}
		isLoadingPage = false
	}

	private func resetAndLoad(debounced: Bool = false) async {
		results = []
		error = nil
		currentPage = 1
		hasMorePages = true
		isLoadingPage = false
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
		RepoSearchResultsList(
			results: results,
			error: error,
			icon: icon,
			isLoading: isLoadingPage,
			hasMorePages: hasMorePages,
			loadingText: "Loading repositories",
			loadingMoreText: "Loading more repositories",
			emptyText: "There are no repositories"
		) {
			await loadNextPage()
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
		.refreshable {
			await resetAndLoad()
		}
		.navigationTitle(Text(navigationTitle))
	}
}
