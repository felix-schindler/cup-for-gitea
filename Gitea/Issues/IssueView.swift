//
//  IssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

struct IssueView: View {
	private let issue: Components.Schemas.Issue

	init(_ issue: Components.Schemas.Issue) {
		self.issue = issue
	}

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading) {
					HStack(spacing: 5) {
						StateIconView(.issue, issue.state)
						Text("\(issue.repository.fullName)#\(issue.number)")
							.foregroundStyle(.secondary)
						if issue.isLocked {
							Image(systemName: "lock")
						}
						Spacer()
						Text(issue.createdAt.toString())
					}.font(.footnote)

					InlineText(markdown: issue.title.emojized())
						.textual.inlineStyle(.gitHub)
						.textual.textSelection(.enabled)

					ScrollView(.horizontal, showsIndicators: false) {
						HStack {
							SmallUserView(issue.user)

							if let pr = issue.pullRequest,
								let url = URL(string: pr.htmlUrl)
							{
								NavigationLink(
									destination: PullRequestLoader(
										owner: issue.repository.owner,
										repo: issue.repository.name,
										index: issue.number
									)
								) {
									Label(
										title: {
											Text("#\(url.lastPathComponent)")
										},
										icon: {
											Image(systemName: pr.merged ? Icons.pull_request_merged.rawValue : Icons.pull_requests.rawValue)
												.foregroundStyle(pr.merged ? .purple : pr.draft ? .secondary : .green)
										})
								}
								.controlSize(.mini)
								.buttonStyle(.bordered)
							}
							if let milestone = issue.milestone {
								NavigationLink {
									MilestonesLoader(owner: issue.repository.owner, repo: issue.repository.name)
								} label: {
									Label(milestone.title.emojized(), systemImage: Icons.milestones.rawValue)
								}
								.controlSize(.mini)
								.buttonStyle(.bordered)
							}
						}
					}

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
							ForEach(issue.assets, id: \.id) { a in
								if let url = URL(string: a.browserDownloadUrl) {
									Link(a.name, destination: url)
								} else {
									Text(a.name)
								}
							}
						}
					}
				}
			}

			if issue.body.isNotEmpty {
				Section {
					StructuredText(markdown: issue.body.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			if issue.assignees != nil || issue.labels.isNotEmpty || issue.milestone != nil {
				Section("Details") {
					if let assignees = issue.assignees {
						DisclosureGroup(
							content: {
								ForEach(assignees, id: \.id) { u in
									SmallUserView(u)
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

					if issue.labels.isNotEmpty {
						Label(
							title: {
								ScrollView(.horizontal) {
									HStack {
										ForEach(issue.labels, id: \.id) { l in
											let bgColor = Color(hex: l.color)
											PillView(
												l.name.emojized(),
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
				}
			}

			if issue.comments != 0 {
				Section("Comments") {
					CommentsLoader(owner: issue.repository.owner, repo: issue.repository.name, iid: issue.number)
				}
			}
		}.toolbar {
			if let url = URL(string: issue.htmlUrl) {
				ShareLink(item: url)
			}
		}
	}
}
