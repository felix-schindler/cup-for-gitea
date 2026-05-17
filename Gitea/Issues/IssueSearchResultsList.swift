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

	var body: some View {
		List {
			if results.isEmpty {
				if let error {
					FailedView(error)
				} else if isLoading {
					LoadingView(loadingText, systemImage: icon)
				} else {
					NoContentView(emptyText, systemImage: icon)
				}
			} else {
				ForEach(results, id: \.id) { issue in
					rowView(for: issue)
						.onAppear {
							if issue.id == results.last?.id, hasMorePages {
								Task { await onLoadMore() }
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
