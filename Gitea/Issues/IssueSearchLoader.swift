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
	@State private var results: [Components.Schemas.Issue] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var currentUsername: String?
	@State private var filters: IssueSearchFilters
	@State private var showFilters = false

	private let debounceNanoseconds: UInt64 = 350_000_000
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
			page: currentPage,
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
			page: currentPage,
			limit: filters.limitValue ?? defaultLimit
		)
	}

	private var needsCurrentUser: Bool {
		(owner != nil && repo != nil && (filters.assigned || filters.created || filters.mentioned))
			|| (owner == nil && repo == nil && filters.myRepos)
	}

	private func resetAndLoad(debounced: Bool = false) async {
		results = []
		error = nil
		currentPage = 1
		hasMorePages = true
		isLoadingPage = false
		await loadNextPage(debounced: debounced)
	}

	private func loadNextPage(debounced: Bool = false) async {
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		defer { isLoadingPage = false }
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			if needsCurrentUser, currentUsername == nil {
				currentUsername = try await Network.shared.client.userGetCurrent().ok.body.json.login
			}
			let results = try await loadIssues()
			if Task.isCancelled { return }
			if results.isEmpty {
				hasMorePages = false
			} else {
				self.results.append(contentsOf: results)
				let limit = filters.limitValue ?? defaultLimit
				if results.count < limit {
					hasMorePages = false
				} else {
					currentPage += 1
				}
			}
			isLoadingPage = false
		} catch {
			if Task.isCancelled { return }
			self.error = error
			isLoadingPage = false
		}
	}

	private func loadIssues() async throws -> [Components.Schemas.Issue] {
		if let owner, let repo {
			return try await Network.shared.client.issueListIssues(
				path: .init(owner: owner, repo: repo),
				query: repoQueryPayload
			).ok.body.json
		}
		return try await Network.shared.client.issueSearchIssues(.init(query: queryPayload)).ok.body.json
	}

	var body: some View {
		IssueSearchResultsList(
			type: type,
			results: results,
			error: error,
			icon: icon,
			isLoading: isLoadingPage,
			hasMorePages: hasMorePages,
			loadingText: loadingText,
			loadingMoreText: loadingMoreText,
			emptyText: emptyText
		) {
			await loadNextPage()
		}
		.searchable(text: $search, prompt: Text(searchPrompt))
		.task(id: queryKey) {
			await resetAndLoad(debounced: true)
		}
		.refreshable {
			await resetAndLoad()
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
			NavigationStack {
				IssueSearchFiltersSheet(filters: $filters)
			}
		}
	}
}
