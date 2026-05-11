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
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)

					ScrollView(.horizontal, showsIndicators: false) {
						HStack {
							SmallUserView(issue.user)

							if let pr = issue.pullRequest {
								NavigationLink(destination: PR_Loader()) {
									Label(
										title: {
											Text("#\(URL(string: pr.htmlUrl)!.lastPathComponent)")
										},
										icon: {
											Image(systemName: pr.merged ? Icons.pull_request_merged.rawValue : pr.draft ? "" : Icons.pull_requests.rawValue)
												.foregroundStyle(pr.merged ? .purple : pr.draft ? .secondary : .green)
										})
								}
								.controlSize(.mini)
								.buttonStyle(.bordered)
							}
							if let milestone = issue.milestone {
								HStack(spacing: 5) {
									Image(systemName: Icons.milestones.rawValue)
									Text(milestone.title)
								}
							}
						}
					}

					ScrollView(.horizontal, showsIndicators: false) {
						HStack {
							Label("\(issue.timeEstimate)", systemImage: "clock")
							if let dueDate = issue.dueDate {
								Label(dueDate.toString(), systemImage: "calendar.badge.checkmark")
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

			// TODO: Display assets, labels, milestone, assignee(s)
		}
	}
}
