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

	var isSearchable: Bool {
		switch self {
		case .search: true
		case .orgMembers, .repoCollaborators: false
		}
	}

	var navigationTitle: LocalizedStringResource {
		switch self {
		case .search: "Search users"
		case .orgMembers: "Members"
		case .repoCollaborators: "Collaborators"
		}
	}

	var loadingText: LocalizedStringResource {
		switch self {
		case .search: "Loading users"
		case .orgMembers: "Loading members"
		case .repoCollaborators: "Loading collaborators"
		}
	}

	var emptyText: LocalizedStringResource {
		switch self {
		case .search: "There are no users"
		case .orgMembers: "This organization has no members"
		case .repoCollaborators: "This repository has no collaborators"
		}
	}

	var icon: String {
		Icons.users.rawValue
	}
}

struct UserSearchLoader: View {
	let context: UserSearchContext

	@State private var search: String = ""
	@State private var results: [Components.Schemas.User] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1

	private let debounceNanoseconds: UInt64 = 350_000_000
	private let defaultLimit = 20

	private var queryKey: String {
		switch context {
		case .search:
			"search|\(search)"
		case .orgMembers(let org):
			"org|\(org)"
		case .repoCollaborators(let owner, let repo):
			"repo|\(owner)|\(repo)"
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
		}
	}

	private func loadNextPage(debounced: Bool = false) async {
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			let page = try await loadUsers()
			if Task.isCancelled { return }
			if page.isEmpty {
				hasMorePages = false
			} else {
				results.append(contentsOf: page)
				if page.count < defaultLimit {
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

	var body: some View {
		listContent
			.task(id: queryKey) {
				await resetAndLoad(debounced: context.isSearchable)
			}
			.refreshable {
				await resetAndLoad()
			}
			.navigationTitle(Text(context.navigationTitle))
	}

	@ViewBuilder
	private var listContent: some View {
		List {
			if results.isEmpty {
				if let error {
					FailedView(error)
				} else if isLoadingPage {
					LoadingView(context.loadingText, systemImage: context.icon)
				} else {
					NoContentView(context.emptyText, systemImage: context.icon)
				}
			} else {
				ForEach(results, id: \.id) { user in
					SmallUserView(user, avatarSize: .medium)
						.onAppear {
							if user.id == results.last?.id, hasMorePages {
								Task { await loadNextPage() }
							}
						}
				}
				if isLoadingPage {
					Section {
						LoadingView("Loading more", systemImage: context.icon)
					}
				} else if let error {
					Section {
						FailedView(error)
					}
				}
			}
		}
		.modifier { view in
			if context.isSearchable {
				view.searchable(text: $search, prompt: Text(searchPrompt))
			} else {
				view
			}
		}
	}
}
