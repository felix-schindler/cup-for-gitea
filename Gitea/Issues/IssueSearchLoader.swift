//
//  IssueSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct IssueSearchFilters: Equatable {
	enum Kind: String, CaseIterable, Identifiable {
		case any
		case issues
		case pulls

		var id: String { rawValue }

		var payload: Operations.IssueSearchIssues.Input.Query._TypePayload? {
			switch self {
			case .any:
				return nil
			case .issues:
				return .issues
			case .pulls:
				return .pulls
			}
		}
	}

	var state: Operations.IssueSearchIssues.Input.Query.StatePayload = .open
	var type: Kind = .issues
	var labels: String = ""
	var milestones: String = ""
	var owner: String = ""
	var createdBy: String = ""
	var team: String = ""
	var assigned: Bool = false
	var created: Bool = false
	var mentioned: Bool = false
	var reviewRequested: Bool = false
	var reviewed: Bool = false
	var since: Date?
	var before: Date?
	var limitText: String = ""

	var taskKey: String {
		[
			state.rawValue,
			type.rawValue,
			labels,
			milestones,
			owner,
			createdBy,
			team,
			assigned.description,
			created.description,
			mentioned.description,
			reviewRequested.description,
			reviewed.description,
			since?.timeIntervalSince1970.description ?? "",
			before?.timeIntervalSince1970.description ?? "",
			limitText
		].joined(separator: "|")
	}

	var labelsValue: String? { trimmedOrNil(labels) }
	var milestonesValue: String? { trimmedOrNil(milestones) }
	var ownerValue: String? { trimmedOrNil(owner) }
	var createdByValue: String? { trimmedOrNil(createdBy) }
	var teamValue: String? { trimmedOrNil(team) }
	var limitValue: Int? { intOrNil(limitText, minimum: 1) }

	private func trimmedOrNil(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}

	private func intOrNil(_ value: String, minimum: Int) -> Int? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard let intValue = Int(trimmed), intValue >= minimum else { return nil }
		return intValue
	}
}

struct IssueSearchLoader: View {
	@State private var search: String = ""
	@State private var results: [Components.Schemas.Issue] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var filters = IssueSearchFilters()
	@State private var showFilters = false
	private let icon = Icons.issues.rawValue
	private let debounceNanoseconds: UInt64 = 350_000_000
	private let defaultLimit = 7

	private var queryKey: String {
		"\(search)|\(filters.taskKey)"
	}

	private var queryPayload: Operations.IssueSearchIssues.Input.Query {
		.init(
			state: filters.state,
			labels: filters.labelsValue,
			milestones: filters.milestonesValue,
			q: search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : search,
			_type: filters.type.payload,
			since: filters.since,
			before: filters.before,
			assigned: filters.assigned ? true : nil,
			created: filters.created ? true : nil,
			mentioned: filters.mentioned ? true : nil,
			reviewRequested: filters.reviewRequested ? true : nil,
			reviewed: filters.reviewed ? true : nil,
			owner: filters.ownerValue,
			createdBy: filters.createdByValue,
			team: filters.teamValue,
			page: currentPage,
			limit: filters.limitValue ?? defaultLimit
		)
	}

	private func resetAndLoad(debounced: Bool = false) async {
		results = []
		error = nil
		currentPage = 1
		hasMorePages = true
		await loadNextPage(debounced: debounced)
	}

	private func loadNextPage(debounced: Bool = false) async {
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			let results = try await Network.shared.client.issueSearchIssues(.init(query: queryPayload)).ok.body.json
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

	var body: some View {
		IssueSearchResultsList(results: results, error: error, icon: icon, isLoading: isLoadingPage, hasMorePages: hasMorePages) {
			await loadNextPage()
		}
			.searchable(text: $search, prompt: Text("Search issues"))
			.task(id: queryKey) {
				await resetAndLoad(debounced: true)
			}
			.refreshable {
				await resetAndLoad()
			}
			.navigationTitle("Issues")
			.toolbar {
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Filters", systemImage: "line.3.horizontal.decrease") {
						HapticFeedback.play(.light)
						showFilters = true
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

private struct IssueSearchResultsList: View {
	let results: [Components.Schemas.Issue]
	let error: Error?
	let icon: String
	let isLoading: Bool
	let hasMorePages: Bool
	let onLoadMore: () async -> Void

	var body: some View {
		List {
			if results.isEmpty {
				if let error {
					FailedView(error)
				} else if isLoading {
					LoadingView("Loading Issues", systemImage: icon)
				} else {
					NoContentView("There are no issues", systemImage: icon)
				}
			} else {
				ForEach(results, id: \.id) { issue in
					SmallIssueView(issue)
						.onAppear {
							if issue.id == results.last?.id, hasMorePages {
								Task { await onLoadMore() }
							}
						}
				}
				if isLoading {
					Section {
						LoadingView("Loading more issues", systemImage: icon)
					}
				} else if let error {
					Section {
						FailedView(error)
					}
				}
			}
		}
	}
}

private struct IssueSearchFiltersSheet: View {
	@Binding var filters: IssueSearchFilters
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		Form {
			Section("State") {
				Picker("State", selection: $filters.state) {
					ForEach(Operations.IssueSearchIssues.Input.Query.StatePayload.allCases, id: \.self) { option in
						Text(option.rawValue.capitalized).tag(option)
					}
				}
				.pickerStyle(.segmented)
			}

			Section("Type") {
				Picker("Type", selection: $filters.type) {
					ForEach(IssueSearchFilters.Kind.allCases) { option in
						Text(option.rawValue.capitalized).tag(option)
					}
				}
			}

			Section("People") {
				Toggle("Assigned to me", isOn: $filters.assigned)
				Toggle("Created by me", isOn: $filters.created)
				Toggle("Mentioned me", isOn: $filters.mentioned)
				Toggle("Review requested", isOn: $filters.reviewRequested)
				Toggle("Reviewed", isOn: $filters.reviewed)
			}

			Section("Dates") {
				Toggle("Updated since", isOn: Binding(
					get: { filters.since != nil },
					set: { isOn in
						filters.since = isOn ? (filters.since ?? Date()) : nil
					}
				))
				if let since = filters.since {
					DatePicker("Since", selection: Binding(
						get: { since },
						set: { filters.since = $0 }
					), displayedComponents: [.date])
				}

				Toggle("Updated before", isOn: Binding(
					get: { filters.before != nil },
					set: { isOn in
						filters.before = isOn ? (filters.before ?? Date()) : nil
					}
				))
				if let before = filters.before {
					DatePicker("Before", selection: Binding(
						get: { before },
						set: { filters.before = $0 }
					), displayedComponents: [.date])
				}
			}

			Section("Labels & Milestones") {
				TextField("Labels (comma-separated)", text: $filters.labels)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Milestones (comma-separated)", text: $filters.milestones)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}

			Section("Scope") {
				TextField("Owner", text: $filters.owner)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Created by", text: $filters.createdBy)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Team", text: $filters.team)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}

			Section("Pagination") {
				TextField("Limit", text: $filters.limitText)
					.keyboardType(.numberPad)
			}
		}
		.navigationTitle("Filters")
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Reset") {
					filters = IssueSearchFilters()
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Done", systemImage: "checkmark") {
					dismiss()
				}
			}
		}
	}
}
