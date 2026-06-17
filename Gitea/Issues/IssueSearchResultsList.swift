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

	private var state: LoadState<[Components.Schemas.Issue]> {
		if results.isEmpty {
			if let error {
				.failed(error)
			} else if isLoading {
				.loading
			} else {
				.loaded([])
			}
		} else {
			if isLoading {
				.loadingMore(results)
			} else if let error {
				.failedMore(results, error)
			} else {
				.loaded(results)
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: loadingText,
			emptyText: emptyText,
			icon: icon,
			load: {},
			loadMore: onLoadMore,
			hasMorePages: hasMorePages,
			loadingMoreText: loadingMoreText
		) { issue in
			switch type {
			case .issues:
				SmallIssueView(issue)
			case .pulls:
				SmallIssueView(issue, isPullRequest: issue.pullRequest != nil)
			}
		}
	}
}
