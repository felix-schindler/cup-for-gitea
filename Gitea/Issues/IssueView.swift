//
//  IssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

struct IssueView: View {
	private enum Item {
		case issue(Components.Schemas.Issue)
		case pullRequest(Components.Schemas.PullRequest)
	}

	private let item: Item

	init(_ issue: Components.Schemas.Issue) {
		self.item = .issue(issue)
	}

	init(_ pullRequest: Components.Schemas.PullRequest) {
		self.item = .pullRequest(pullRequest)
	}

	var body: some View {
		List {
			Section {
				header
			}

			if bodyText.isNotEmpty {
				Section {
					StructuredText(markdown: bodyText.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			if hasDetails {
				Section("Details") {
					details
				}
			}

			if comments != 0 {
				Section("Comments") {
					CommentsLoader(owner: owner, repo: repo, iid: number)
				}
			}
		}.toolbar {
			if let url = URL(string: htmlUrl) {
				ShareLink(item: url)
			}
		}
		.navigationTitle(navigationTitle)
		.navigationBarTitleDisplayMode(.inline)
	}

	private var header: some View {
		VStack(alignment: .leading) {
			HStack(spacing: 5) {
				stateIcon
				Text("\(repositoryFullName)#\(number)")
					.foregroundStyle(.secondary)
				if isLocked {
					Image(systemName: "lock")
				}
				Spacer()
				Text(createdAt.toString())
			}.font(.footnote)

			InlineText(markdown: title.emojized())
				.textual.inlineStyle(.gitHub)
				.textual.textSelection(.enabled)

			headerMetadata

			issueMetadata
		}
	}

	@ViewBuilder
	private var stateIcon: some View {
		switch item {
		case .issue(let issue):
			StateIconView(.issue, issue.state)
		case .pullRequest(let pullRequest):
			StateIconView(.pull, pullRequest.notificationState, isDraft: pullRequest.draft)
		}
	}

	@ViewBuilder
	private var headerMetadata: some View {
		ScrollView(.horizontal, showsIndicators: false) {
			HStack(spacing: 5) {
				switch item {
				case .issue(let issue):
					SmallUserView(issue.user)
					if let pr = issue.pullRequest,
						let url = URL(string: pr.htmlUrl)
					{
						NavigationLink(
							destination: PullRequestLoader(owner: owner, repo: repo, index: number)
						) {
							Label(
								title: {
									Text("#\(url.lastPathComponent)")
								},
								icon: {
									StateIconView(.pull, issue.pullRequestState, isDraft: pr.draft)
								})
						}
						.controlSize(.mini)
						.buttonStyle(.bordered)
					}
					if let milestone = issue.milestone {
						NavigationLink {
							MilestonesLoader(owner: owner, repo: repo)
						} label: {
							Label(milestone.title.emojized(), systemImage: Icons.milestones.rawValue)
						}
						.controlSize(.mini)
						.buttonStyle(.bordered)
					}
				case .pullRequest(let pullRequest):
					SmallUserView(pullRequest.user)
					branchPill(pullRequest.head.ref)
					Image(systemName: "arrow.right")
					branchPill(pullRequest.base.ref)
				}
			}
		}.font(.footnote)
	}

	@ViewBuilder
	private func branchPill(_ name: String) -> some View {
		PillView(
			name,
			bgColor: .blue,
			fgColor: .white,
			cornerRadius: 5
		)
		.monospaced()
		.textSelection(.enabled)
	}

	@ViewBuilder
	private var issueMetadata: some View {
		switch item {
		case .issue(let issue):
			if issue.timeEstimate != 0 || issue.dueDate != nil {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						if issue.timeEstimate != 0 {
							PillView("\(issue.timeEstimate)", systemImage: "clock")
								.font(.footnote)
						}
						if let dueDate = issue.dueDate {
							PillView(dueDate.toString(), systemImage: "calendar.badge.checkmark")
						}
					}
				}
			}

			if issue.assets.isNotEmpty {
				ScrollView(.horizontal, showsIndicators: false) {
					ForEach(issue.assets, id: \.id) { asset in
						if let url = URL(string: asset.browserDownloadUrl) {
							Link(asset.name, destination: url)
						} else {
							Text(asset.name)
						}
					}
				}
			}
		case .pullRequest(let pullRequest):
			if pullRequest.draft {
				PillView("Draft", systemImage: "pencil")
					.font(.footnote)
			}
		}
	}

	@ViewBuilder
	private var details: some View {
		switch item {
		case .issue(let issue):
			commonDetails(assignees: issue.assignees, labels: issue.labels, milestoneTitle: issue.milestone?.title)
		case .pullRequest(let pullRequest):
			commonDetails(
				assignees: pullRequest.assignees,
				labels: pullRequest.labels,
				milestoneTitle: pullRequest.milestone?.title
			)
			pullRequestDetails(pullRequest)
		}
	}

	@ViewBuilder
	private func commonDetails(
		assignees: [Components.Schemas.User]?,
		labels: [Components.Schemas.Label],
		milestoneTitle: String?
	) -> some View {
		if let assignees, assignees.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(assignees, id: \.id) { user in
						SmallUserView(user)
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Assignees")
								Spacer()
								Text("\(assignees.count)")
							}
						},
						icon: {
							Image(systemName: Icons.users.rawValue)
						})
				})
		}

		if labels.isNotEmpty {
			Label(
				title: {
					ScrollView(.horizontal) {
						HStack {
							ForEach(labels, id: \.id) { label in
								let bgColor = Color(hex: label.color)
								PillView(
									label.name.emojized(),
									bgColor: bgColor,
									fgColor: bgColor.adaptiveText()
								)
							}
						}
					}
				},
				icon: {
					Image(systemName: Icons.topics.rawValue)
				}
			)
		}

		if let milestoneTitle {
			Label(milestoneTitle.emojized(), systemImage: Icons.milestones.rawValue)
		}
	}

	@ViewBuilder
	private func pullRequestDetails(_ pullRequest: Components.Schemas.PullRequest) -> some View {
		if let requestedReviewers = pullRequest.requestedReviewers, requestedReviewers.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(requestedReviewers, id: \.id) { user in
						SmallUserView(user)
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Requested reviewers")
								Spacer()
								Text("\(requestedReviewers.count)")
							}
						},
						icon: {
							Image(systemName: Icons.users.rawValue)
						})
				}
			)
		}

		if let requestedTeams = pullRequest.requestedReviewersTeams, requestedTeams.isNotEmpty {
			DisclosureGroup(
				content: {
					ForEach(requestedTeams, id: \.id) { team in
						Label(team.name, systemImage: "person.3")
					}
				},
				label: {
					Label(
						title: {
							HStack {
								Text("Requested teams")
								Spacer()
								Text("\(requestedTeams.count)")
							}
						},
						icon: {
							Image(systemName: "person.3")
						})
				}
			)
		}

		if let additions = pullRequest.additions,
			let deletions = pullRequest.deletions,
			let changedFiles = pullRequest.changedFiles
		{
			Label(
				title: {
					HStack {
						Text("\(changedFiles) files changed")
						Spacer()
						HStack {
							Text("+\(additions)")
								.foregroundStyle(.green)
							Text("-\(deletions)")
								.foregroundStyle(.red)
						}.monospaced()
					}
				},
				icon: {
					Image(systemName: "doc.text")
				}
			)
		}

		if pullRequest.reviewComments != 0 {
			Label(
				title: {
					HStack {
						Text("Review comments")
						Spacer()
						Text("\(pullRequest.reviewComments)")
					}
				},
				icon: {
					Image(systemName: "text.bubble")
				})
		}
	}

	private var hasDetails: Bool {
		switch item {
		case .issue(let issue):
			(issue.assignees?.isNotEmpty == true) || issue.labels.isNotEmpty || issue.milestone != nil
		case .pullRequest(let pullRequest):
			(pullRequest.assignees?.isNotEmpty == true)
				|| pullRequest.labels.isNotEmpty
				|| pullRequest.milestone != nil
				|| (pullRequest.requestedReviewers?.isNotEmpty == true)
				|| (pullRequest.requestedReviewersTeams?.isNotEmpty == true)
				|| pullRequest.additions != nil
				|| pullRequest.deletions != nil
				|| pullRequest.changedFiles != nil
				|| pullRequest.reviewComments != 0
		}
	}

	private var navigationTitle: LocalizedStringResource {
		switch item {
		case .issue:
			"Issue"
		case .pullRequest:
			"Pull Request"
		}
	}

	private var repositoryFullName: String {
		switch item {
		case .issue(let issue):
			issue.repository.fullName
		case .pullRequest(let pullRequest):
			pullRequest.base.repo.fullName
		}
	}

	private var owner: String {
		switch item {
		case .issue(let issue):
			issue.repository.owner
		case .pullRequest(let pullRequest):
			pullRequest.base.repo.owner.login
		}
	}

	private var repo: String {
		switch item {
		case .issue(let issue):
			issue.repository.name
		case .pullRequest(let pullRequest):
			pullRequest.base.repo.name
		}
	}

	private var number: Int64 {
		switch item {
		case .issue(let issue):
			issue.number
		case .pullRequest(let pullRequest):
			pullRequest.number
		}
	}

	private var isLocked: Bool {
		switch item {
		case .issue(let issue):
			issue.isLocked
		case .pullRequest(let pullRequest):
			pullRequest.isLocked
		}
	}

	private var createdAt: Date {
		switch item {
		case .issue(let issue):
			issue.createdAt
		case .pullRequest(let pullRequest):
			pullRequest.createdAt
		}
	}

	private var title: String {
		switch item {
		case .issue(let issue):
			issue.title
		case .pullRequest(let pullRequest):
			pullRequest.title
		}
	}

	private var bodyText: String {
		switch item {
		case .issue(let issue):
			issue.body
		case .pullRequest(let pullRequest):
			pullRequest.body
		}
	}

	private var comments: Int64 {
		switch item {
		case .issue(let issue):
			issue.comments
		case .pullRequest(let pullRequest):
			pullRequest.comments
		}
	}

	private var htmlUrl: String {
		switch item {
		case .issue(let issue):
			issue.htmlUrl
		case .pullRequest(let pullRequest):
			pullRequest.htmlUrl
		}
	}
}
