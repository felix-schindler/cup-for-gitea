//
//  IssueSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct IssueSearchLoader: View {
	let type: Operations.IssueSearchIssues.Input.Query._TypePayload
	let owner: String?
	let repo: String?

	@State private var search: String = ""
	@State private var state = LoadState<[Components.Schemas.Issue]>.loading
	@State private var paging = Paging()
	@State private var currentUsername: String?
	@State private var filters: IssueSearchFilters
	@State private var showFilters = false

	private let defaultLimit = 7
	private var navigationTitle: LocalizedStringResource {
		switch type {
		case .issues: "Issues"
		case .pulls: "Pull Requests"
		}
	}
	private var searchPrompt: LocalizedStringResource { "Search \(typeLabel.lowercased())" }
	private var emptyText: LocalizedStringResource { "There are no \(typeLabel.lowercased())" }
	private var loadingText: LocalizedStringResource { "Loading \(typeLabel)" }
	private var loadingMoreText: LocalizedStringResource { "Loading more \(typeLabel.lowercased())" }
	private var icon: String {
		switch type {
		case .issues:
			return Icons.issues.rawValue
		case .pulls:
			return Icons.pull_requests.rawValue
		@unknown default:
			return Icons.issues.rawValue
		}
	}
	private var typeLabel: String {
		switch type {
		case .issues:
			"Issues"
		case .pulls:
			"Pull Requests"
		}
	}

	private var queryKey: String {
		"\(owner ?? "")|\(repo ?? "")|\(search)|\(filters.taskKey)"
	}

	init(type: Operations.IssueSearchIssues.Input.Query._TypePayload, owner: String? = nil, repo: String? = nil, milestonesFilter: String? = nil, myRepos: Bool? = nil) {
		self.type = type
		self.owner = owner
		self.repo = repo
		let defaultMyRepos = myRepos ?? (owner == nil && repo == nil)
		self._filters = State(initialValue: IssueSearchFilters(milestones: milestonesFilter ?? "", myRepos: defaultMyRepos))
	}

	private var queryPayload: Operations.IssueSearchIssues.Input.Query {
		.init(
			state: filters.state,
			labels: filters.labelsValue,
			milestones: filters.milestonesValue,
			q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
			_type: type,
			since: filters.since,
			before: filters.before,
			assigned: filters.assigned ? true : nil,
			created: filters.created ? true : nil,
			mentioned: filters.mentioned ? true : nil,
			reviewRequested: filters.reviewRequested ? true : nil,
			reviewed: filters.reviewed ? true : nil,
			owner: filters.myRepos ? currentUsername : filters.ownerValue,
			createdBy: filters.createdByValue,
			team: filters.teamValue,
			page: paging.page,
			limit: filters.limitValue ?? defaultLimit
		)
	}

	private var repoQueryPayload: Operations.IssueListIssues.Input.Query {
		.init(
			state: .init(rawValue: filters.state.rawValue),
			labels: filters.labelsValue,
			q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
			_type: .init(rawValue: type.rawValue),
			milestones: filters.milestonesValue,
			since: filters.since,
			before: filters.before,
			createdBy: filters.created ? currentUsername : filters.createdByValue,
			assignedBy: filters.assigned ? currentUsername : nil,
			mentionedBy: filters.mentioned ? currentUsername : nil,
			page: paging.page,
			limit: filters.limitValue ?? defaultLimit
		)
	}

	private var needsCurrentUser: Bool {
		(owner != nil && repo != nil && (filters.assigned || filters.created || filters.mentioned))
			|| (owner == nil && repo == nil && filters.myRepos)
	}

	private func resetAndLoad(debounced: Bool = false) async {
		guard !paging.isLoading else { return }
		state = .loading
		paging.reset()
		await loadNextPage(debounced: debounced)
	}

	private func loadNextPage(debounced: Bool = false) async {
		if needsCurrentUser, currentUsername == nil {
			currentUsername = try? await Network.shared.client.userGetCurrent().ok.body.json.login
		}
		if debounced {
			try? await Task.sleep(nanoseconds: 350_000_000)
			guard !Task.isCancelled else { return }
		}
		(state, paging) = await paging.nextPage(state: state, limit: filters.limitValue ?? defaultLimit) { page in
			let results = try await loadIssues(page: page)
			return results
		}
	}

	private func loadIssues(page: Int) async throws -> [Components.Schemas.Issue] {
		if let owner, let repo {
			return try await Network.shared.client.issueListIssues(
				path: .init(owner: owner, repo: repo),
				query: .init(
					state: .init(rawValue: filters.state.rawValue),
					labels: filters.labelsValue,
					q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
					_type: .init(rawValue: type.rawValue),
					milestones: filters.milestonesValue,
					since: filters.since,
					before: filters.before,
					createdBy: filters.created ? currentUsername : filters.createdByValue,
					assignedBy: filters.assigned ? currentUsername : nil,
					mentionedBy: filters.mentioned ? currentUsername : nil,
					page: page,
					limit: filters.limitValue ?? defaultLimit
				)
			).ok.body.json
		}
		return try await Network.shared.client.issueSearchIssues(
			.init(
				query: .init(
					state: filters.state,
					labels: filters.labelsValue,
					milestones: filters.milestonesValue,
					q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
					_type: type,
					since: filters.since,
					before: filters.before,
					assigned: filters.assigned ? true : nil,
					created: filters.created ? true : nil,
					mentioned: filters.mentioned ? true : nil,
					reviewRequested: filters.reviewRequested ? true : nil,
					reviewed: filters.reviewed ? true : nil,
					owner: filters.myRepos ? currentUsername : filters.ownerValue,
					createdBy: filters.createdByValue,
					team: filters.teamValue,
					page: page,
					limit: filters.limitValue ?? defaultLimit
				))
		).ok.body.json
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: loadingText,
			emptyText: emptyText,
			icon: icon,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore,
			loadingMoreText: loadingMoreText
		) { issue in
			switch type {
			case .issues:
				SmallIssueView(issue)
			case .pulls:
				SmallIssueView(issue, isPullRequest: issue.pullRequest != nil)
			}
		}
		.searchable(text: $search, prompt: Text(searchPrompt))
		.task(id: queryKey) {
			await resetAndLoad(debounced: true)
		}
		.navigationTitle(Text(navigationTitle))
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				Button("Filters", systemImage: "line.3.horizontal.decrease") {
					HapticFeedback.play(.light)
					showFilters = true
				}
			}
			if let owner, let repo {
				if type == .issues {
					ToolbarItem(placement: .navigationBarTrailing) {
						NavigationLink(destination: NewIssueView(owner: owner, repo: repo)) {
							Label("New Issue", systemImage: "plus")
						}
					}
				} else if type == .pulls {
					ToolbarItem(placement: .navigationBarTrailing) {
						NavigationLink(destination: NewPullRequestView(owner: owner, repo: repo)) {
							Label("New Pull Request", systemImage: "plus")
						}
					}
				}
			}
		}
		.sheet(isPresented: $showFilters) {
			IssueSearchFiltersSheet(filters: $filters)
		}
	}
}
