//
//  PullRequestView.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI
import Textual

struct PullRequestView: View {
	private let pullRequest: Components.Schemas.PullRequest

	init(_ pullRequest: Components.Schemas.PullRequest) {
		self.pullRequest = pullRequest
	}

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading) {
					HStack(spacing: 5) {
						StateIconView(.pull, pullRequest.merged ? .merged : (pullRequest.state == .open ? .open : .closed))
						Text("\(pullRequest.base.repo.fullName)#\(pullRequest.number)")
							.foregroundStyle(.secondary)
						if pullRequest.isLocked {
							Image(systemName: "lock")
						}
						Spacer()
						Text(pullRequest.createdAt.toString())
					}.font(.footnote)

					InlineText(markdown: pullRequest.title.emojized())
						.textual.inlineStyle(.gitHub)
						.textual.textSelection(.enabled)

					ScrollView(.horizontal, showsIndicators: false) {
						HStack(spacing: 5) {
							SmallUserView(pullRequest.user)

							PillView(
								pullRequest.head.ref,
								bgColor: .blue,
								fgColor: .white,
								cornerRadius: 5
							)
							.monospaced()
							.textSelection(.enabled)

							Image(systemName: "arrow.right")

							PillView(
								pullRequest.base.ref,
								bgColor: .blue,
								fgColor: .white,
								cornerRadius: 5
							)
							.monospaced()
							.textSelection(.enabled)
						}
					}.font(.footnote)

					if pullRequest.draft {
						PillView("Draft", systemImage: "pencil")
							.font(.footnote)
					}
				}
			}

			if pullRequest.assignees != nil
				|| pullRequest.labels.isNotEmpty
				|| pullRequest.milestone != nil
				|| pullRequest.requestedReviewers != nil
				|| pullRequest.requestedReviewersTeams != nil
				|| pullRequest.additions != nil
				|| pullRequest.deletions != nil
				|| pullRequest.changedFiles != nil
				|| pullRequest.reviewComments != 0
			{
				Section {
					if let assignees = pullRequest.assignees, assignees.isNotEmpty {
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
							}
						)
					}

					if pullRequest.labels.isNotEmpty {
						Label(
							title: {
								ScrollView(.horizontal) {
									HStack {
										ForEach(pullRequest.labels, id: \.id) { l in
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

					if let milestone = pullRequest.milestone {
						Label(milestone.title.emojized(), systemImage: Icons.milestones.rawValue)
					}

					if let requestedReviewers = pullRequest.requestedReviewers, requestedReviewers.isNotEmpty {
						DisclosureGroup(
							content: {
								ForEach(requestedReviewers, id: \.id) { u in
									SmallUserView(u)
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

					if let requestedReviewersTeams = pullRequest.requestedReviewersTeams, requestedReviewersTeams.isNotEmpty {
						DisclosureGroup(
							content: {
								ForEach(requestedReviewersTeams, id: \.id) { team in
									Label(team.name, systemImage: "person.3")
								}
							},
							label: {
								Label(
									title: {
										HStack {
											Text("Requested teams")
											Spacer()
											Text("\(requestedReviewersTeams.count)")
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
								Text("Review comments")
								Spacer()
								Text("\(pullRequest.reviewComments)")
							},
							icon: {
								Image(systemName: "text.bubble")
							})
					}
				}

				if pullRequest.body.isNotEmpty {
					Section {
						StructuredText(markdown: pullRequest.body.emojized())
							.textual.structuredTextStyle(.gitHub)
							.textual.textSelection(.enabled)
					}
				}

				if pullRequest.comments != 0 {
					Section("Comments") {
						CommentsLoader(owner: pullRequest.base.repo.owner.login, repo: pullRequest.base.repo.name, iid: pullRequest.number)
					}
				}
			}
		}.toolbar {
			if let url = URL(string: pullRequest.htmlUrl) {
				ShareLink(item: url)
			}
		}
		.navigationTitle("Pull Request")
		.navigationBarTitleDisplayMode(.inline)
	}
}
