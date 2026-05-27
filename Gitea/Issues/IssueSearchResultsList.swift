//
//  IssueSearchResultsList.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct IssueSearchResultsList: View {
	let type: Operations.IssueSearchIssues.Input.Query._TypePayload
	let results: [Components.Schemas.Issue]
	let error: Error?
	let icon: String
	let isLoading: Bool
	let hasMorePages: Bool
	let loadingText: LocalizedStringResource
	let loadingMoreText: LocalizedStringResource
	let emptyText: LocalizedStringResource
	let onLoadMore: () async -> Void

	var pinnedIssues: [Components.Schemas.Issue] = []
	var pinnedPullRequests: [Components.Schemas.PullRequest] = []
	var onPin: ((Components.Schemas.Issue) -> Void)?
	var onUnpin: ((Components.Schemas.Issue) -> Void)?

	private var pinnedIds: Set<Int64> {
		var ids = Set(pinnedIssues.map(\.id))
		for pr in pinnedPullRequests {
			ids.insert(pr.id)
		}
		return ids
	}

	var body: some View {
		List {
			if !pinnedIssues.isEmpty || !pinnedPullRequests.isEmpty {
				Section("Pinned") {
					ForEach(pinnedIssues, id: \.id) { issue in
						SmallIssueView(issue)
							.swipeActions(edge: .leading) {
								Button("Unpin", systemImage: "pin.slash") {
									onUnpin?(issue)
								}.tint(.orange)
							}
					}
					ForEach(pinnedPullRequests, id: \.id) { pr in
						SmallIssueView(pr)
					}
				}
			}

			if results.isEmpty && pinnedIssues.isEmpty && pinnedPullRequests.isEmpty {
				if let error {
					FailedView(error)
				} else if isLoading {
					LoadingView(loadingText, systemImage: icon)
				} else {
					NoContentView(emptyText, systemImage: icon)
				}
			} else {
				ForEach(results, id: \.id) { issue in
					if !pinnedIds.contains(issue.id) {
						rowView(for: issue)
							.swipeActions(edge: .leading) {
								if onPin != nil {
									Button("Pin", systemImage: "pin") {
										onPin?(issue)
									}.tint(.orange)
								}
							}
							.onAppear {
								if issue.id == results.last?.id, hasMorePages {
									Task { await onLoadMore() }
								}
							}
					}
				}
				if isLoading {
					Section {
						LoadingView(loadingMoreText, systemImage: icon)
					}
				} else if let error {
					Section {
						FailedView(error)
					}
				}
			}
		}
	}

	@ViewBuilder
	private func rowView(for issue: Components.Schemas.Issue) -> some View {
		switch type {
		case .issues:
			SmallIssueView(issue)
		case .pulls:
			SmallIssueView(issue, isPullRequest: issue.pullRequest != nil)
		}
	}
}
