//
//  UserSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

enum UserSearchContext: Hashable {
	case search
	case orgMembers(org: String)
	case repoCollaborators(owner: String, repo: String)
	case teamMembers(teamId: Int64)

	var isSearchable: Bool {
		switch self {
		case .search: true
		case .orgMembers, .repoCollaborators, .teamMembers: false
		}
	}

	var navigationTitle: LocalizedStringResource {
		switch self {
		case .search: "Search users"
		case .orgMembers: "Members"
		case .repoCollaborators: "Collaborators"
		case .teamMembers: "Members"
		}
	}

	var loadingText: LocalizedStringResource {
		switch self {
		case .search: "Loading users"
		case .orgMembers: "Loading members"
		case .repoCollaborators: "Loading collaborators"
		case .teamMembers: "Loading members"
		}
	}

	var emptyText: LocalizedStringResource {
		switch self {
		case .search: "There are no users"
		case .orgMembers: "This organization has no members"
		case .repoCollaborators: "This repository has no collaborators"
		case .teamMembers: "This team has no members"
		}
	}

	var icon: String {
		Icons.users.rawValue
	}
}

struct UserSearchLoader: View {
	let context: UserSearchContext

	@State private var search: String = ""
	@State private var state = LoadState<[Components.Schemas.User]>.loading
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var isLoadingMore = false

	private let debounceNanoseconds: UInt64 = 350_000_000
	private let defaultLimit = 7

	private var queryKey: String {
		switch context {
		case .search:
			"search|\(search)"
		case .orgMembers(let org):
			"org|\(org)"
		case .repoCollaborators(let owner, let repo):
			"repo|\(owner)|\(repo)"
		case .teamMembers(let teamId):
			"team|\(teamId)"
		}
	}

	private var searchPrompt: LocalizedStringResource { "Search users" }

	private func loadUsers() async throws -> [Components.Schemas.User] {
		switch context {
		case .search:
			try await Network.shared.client.userSearch(
				.init(
					query: .init(
						q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
						page: currentPage,
						limit: defaultLimit
					))
			).ok.body.json.data
		case .orgMembers(let org):
			try await Network.shared.client.orgListMembers(
				path: .init(org: org),
				query: .init(page: currentPage, limit: defaultLimit)
			).ok.body.json
		case .repoCollaborators(let owner, let repo):
			try await Network.shared.client.repoListCollaborators(
				path: .init(owner: owner, repo: repo),
				query: .init(page: currentPage, limit: defaultLimit)
			).ok.body.json
		case .teamMembers(let teamId):
			try await Network.shared.client.orgListTeamMembers(
				path: .init(id: teamId),
				query: .init(page: currentPage, limit: defaultLimit)
			).ok.body.json
		}
	}

	private func loadNextPage(debounced: Bool = false) async {
		guard !isLoadingMore, hasMorePages else { return }
		isLoadingMore = true
		defer { isLoadingMore = false }
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		let currentItems: [Components.Schemas.User]
		if case .loaded(let items) = state {
			currentItems = items
			state = .loadingMore(items)
		} else {
			currentItems = []
		}
		do {
			let page = try await loadUsers()
			if Task.isCancelled { return }
			state = .loaded(currentItems + page)
			if page.count < defaultLimit {
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

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: context.loadingText,
			emptyText: context.emptyText,
			icon: context.icon,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: hasMorePages
		) { user in
			SmallUserView(user, avatarSize: .medium)
		}
		.modifier { view in
			if context.isSearchable {
				view.searchable(text: $search, prompt: Text(searchPrompt))
			} else {
				view
			}
		}
		.task(id: queryKey) {
			await resetAndLoad(debounced: context.isSearchable)
		}
		.navigationTitle(Text(context.navigationTitle))
	}
}
