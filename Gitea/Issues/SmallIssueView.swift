//
//  SmallIssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct SmallIssueView: View {
	private enum Item {
		case issue(Components.Schemas.Issue, isPullRequest: Bool)
		case pullRequest(Components.Schemas.PullRequest)

		var data: any IssueDisplayable {
			switch self {
			case .issue(let issue, _): issue
			case .pullRequest(let pr): pr
			}
		}
	}

	private let item: Item

	init(_ issue: Components.Schemas.Issue, isPullRequest: Bool = false) {
		self.item = .issue(issue, isPullRequest: isPullRequest)
	}

	init(_ pullRequest: Components.Schemas.PullRequest) {
		self.item = .pullRequest(pullRequest)
	}

	var body: some View {
		NavigationLink(destination: destination) {
			VStack(alignment: .leading) {
				HStack {
					stateIcon
					ScrollView(.horizontal, showsIndicators: false) {
						Text("\(item.data.displayRepositoryFullName)#\(item.data.displayNumber)")
							.foregroundStyle(.secondary)
					}
					if item.data.displayIsLocked {
						Image(systemName: "lock")
					}
					Spacer()
					if let createdAt = item.data.displayCreatedAt {
						Text(createdAt.toString())
					}
				}.font(.footnote)

				if let inline = try? AttributedString(markdown: item.data.displayTitle.emojized()) {
					Text(inline)
				} else {
					Text(item.data.displayTitle.emojized())
				}

				HStack {
					ScrollView(.horizontal, showsIndicators: false) {
						userView
					}
					Spacer()
					Image(systemName: Icons.comments.rawValue)
						.font(.footnote)
						.foregroundStyle(.foreground)
					Text("\(item.data.displayComments)")
						.font(.footnote)
				}
			}
		}
	}

	@ViewBuilder
	private var destination: some View {
		switch item {
		case .issue(let issue, let isPullRequest):
			if isPullRequest {
				PullRequestLoader(owner: issue.repository?.owner ?? "", repo: issue.repository?.name ?? "", index: issue.number ?? 0)
			} else {
				IssueView(issue)
			}
		case .pullRequest(let pullRequest):
			IssueView(pullRequest)
		}
	}

	@ViewBuilder
	private var stateIcon: some View {
		switch item {
		case .issue(let issue, let isPullRequest):
			if isPullRequest {
				StateIconView(.pull, issue.pullRequestState, isDraft: issue.pullRequest?.draft == true)
			} else {
				StateIconView(.issue, issue.state?.notificationState ?? .closed)
			}
		case .pullRequest(let pullRequest):
			StateIconView(.pull, pullRequest.notificationState)
		}
	}

	@ViewBuilder
	private var userView: some View {
		switch item {
		case .issue(let issue, _):
			if let user = issue.user {
				SmallUserView(user)
			}
		case .pullRequest(let pullRequest):
			if let user = pullRequest.user {
				SmallUserView(user)
			}
		}
	}
}

extension Components.Schemas.StateType {
	var notificationState: Components.Schemas.NotificationSubject.StatePayload {
		switch self {
		case .open: return .open
		case .closed: return .closed
		}
	}
}

extension Components.Schemas.Issue {
	var pullRequestState: Components.Schemas.NotificationSubject.StatePayload {
		if pullRequest?.merged == true {
			return .merged
		}
		return state?.notificationState ?? .closed
	}
}

extension Components.Schemas.PullRequest {
	var notificationState: Components.Schemas.NotificationSubject.StatePayload {
		if merged == true {
			return .merged
		}
		return state?.value1.notificationState ?? .closed
	}
}
