//
//  IssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

protocol IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { get }
	var displayRepositoryFullName: String { get }
	var displayOwner: String { get }
	var displayRepo: String { get }
	var displayNumber: Int64 { get }
	var displayIsLocked: Bool { get }
	var displayCreatedAt: Date { get }
	var displayTitle: String { get }
	var displayBody: String { get }
	var displayComments: Int64 { get }
	var displayHtmlUrl: String { get }
}

extension Components.Schemas.Issue: IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { "Issue" }
	var displayRepositoryFullName: String { repository.fullName }
	var displayOwner: String { repository.owner }
	var displayRepo: String { repository.name }
	var displayNumber: Int64 { number }
	var displayIsLocked: Bool { isLocked }
	var displayCreatedAt: Date { createdAt }
	var displayTitle: String { title }
	var displayBody: String { body }
	var displayComments: Int64 { comments }
	var displayHtmlUrl: String { htmlUrl }
}

extension Components.Schemas.PullRequest: IssueDisplayable {
	var displayNavigationTitle: LocalizedStringResource { "Pull Request" }
	var displayRepositoryFullName: String { base.repo.fullName }
	var displayOwner: String { base.repo.owner.login }
	var displayRepo: String { base.repo.name }
	var displayNumber: Int64 { number }
	var displayIsLocked: Bool { isLocked }
	var displayCreatedAt: Date { createdAt }
	var displayTitle: String { title }
	var displayBody: String { body }
	var displayComments: Int64 { comments }
	var displayHtmlUrl: String { htmlUrl }
}

struct IssueView: View {
	private enum Item {
		case issue(Components.Schemas.Issue)
		case pullRequest(Components.Schemas.PullRequest)

		var data: any IssueDisplayable {
			switch self {
			case .issue(let issue): issue
			case .pullRequest(let pr): pr
			}
		}
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

			if item.data.displayBody.isNotEmpty {
				Section {
					StructuredText(markdown: item.data.displayBody.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			if hasDetails {
				Section("Details") {
					details
				}
			}

			if item.data.displayComments != 0 {
				Section("Comments") {
					CommentsLoader(owner: item.data.displayOwner, repo: item.data.displayRepo, iid: item.data.displayNumber)
				}
			}
		}.toolbar {
			if let url = URL(string: item.data.displayHtmlUrl) {
				ShareLink(item: url)
			}
		}
		.navigationTitle(Text(item.data.displayNavigationTitle))
		.navigationBarTitleDisplayMode(.inline)
	}

	private var header: some View {
		VStack(alignment: .leading) {
			HStack {
				stateIcon
				Text("\(item.data.displayRepositoryFullName)#\(item.data.displayNumber)")
					.foregroundStyle(.secondary)
				if item.data.displayIsLocked {
					Image(systemName: "lock")
				}
				Spacer()
				Text(item.data.displayCreatedAt.toString())
			}.font(.footnote)

			InlineText(markdown: item.data.displayTitle.emojized())
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
			HStack {
				switch item {
				case .issue(let issue):
					SmallUserView(issue.user)
					if let pr = issue.pullRequest,
						let url = URL(string: pr.htmlUrl)
					{
						NavigationLink(
							destination: PullRequestLoader(owner: item.data.displayOwner, repo: item.data.displayRepo, index: item.data.displayNumber)
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
							MilestonesLoader(owner: item.data.displayOwner, repo: item.data.displayRepo)
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
			verbatim: name,
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
							PillView(verbatim: "\(issue.timeEstimate)", systemImage: "clock")
								.font(.footnote)
						}
						if let dueDate = issue.dueDate {
							PillView(verbatim: dueDate.toString(), systemImage: "calendar.badge.checkmark")
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
									verbatim: label.name.emojized(),
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
}
