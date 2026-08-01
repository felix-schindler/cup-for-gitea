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
	@State private var paging = Paging()

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

	private func loadUsers(page: Int) async throws -> [Components.Schemas.User] {
		switch context {
		case .search:
			try await Network.shared.client.userSearch(
				.init(
					query: .init(
						q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
						page: page,
						limit: defaultLimit
					))
			).ok.body.json.data ?? []
		case .orgMembers(let org):
			try await Network.shared.client.orgListMembers(
				path: .init(org: org),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json
		case .repoCollaborators(let owner, let repo):
			try await Network.shared.client.repoListCollaborators(
				path: .init(owner: owner, repo: repo),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json
		case .teamMembers(let teamId):
			try await Network.shared.client.orgListTeamMembers(
				path: .init(id: teamId),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json
		}
	}

	private func loadNextPage(debounced: Bool = false) async {
		if debounced {
			try? await Task.sleep(nanoseconds: 350_000_000)
			guard !Task.isCancelled else { return }
		}
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit) { page in
			try await loadUsers(page: page)
		}
	}

	private func resetAndLoad(debounced: Bool = false) async {
		guard !paging.isLoading else { return }
		state = .loading
		paging.reset()
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
			hasMorePages: paging.hasMore
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
