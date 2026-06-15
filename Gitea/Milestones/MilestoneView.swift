//
//  MilestoneView.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import SwiftUI
import Textual

struct MilestoneView: View {
	private let milestone: Components.Schemas.Milestone
	private let owner: String
	private let repo: String

	init(_ milestone: Components.Schemas.Milestone, owner: String, repo: String) {
		self.milestone = milestone
		self.owner = owner
		self.repo = repo
	}

	var body: some View {
		Section {
			VStack(alignment: .leading) {
				HStack {
					if milestone.state == .open {
						PillView("Open", systemImage: Icons.milestones.rawValue, bgColor: .green, fgColor: .white)
					} else {
						PillView("Closed", systemImage: Icons.milestones.rawValue, bgColor: .red, fgColor: .white)
					}
				}.font(.footnote)

				let total = milestone.openIssues + milestone.closedIssues
				if total > 0 {
					let progress = Double(milestone.closedIssues) / Double(total)
					ProgressView(value: progress) {
						Text("\(milestone.closedIssues) / \(total) issues closed")
							.font(.footnote)
					}
				}

				if milestone.description.isNotEmpty {
					StructuredText(markdown: milestone.description.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			NavigationLink {
				IssueSearchLoader(type: .issues, owner: owner, repo: repo, milestonesFilter: milestone.title)
			} label: {
				Label("Open issues", systemImage: Icons.issues.rawValue)
			}
		} header: {
			HStack {
				Text(milestone.title.emojized())
				Spacer()
				Text(milestone.createdAt.toString(.short))
					.font(.footnote)
			}
		}
		.swipeActions {
			let milestonePath = "\(owner)/\(repo)/milestone/\(milestone.id)"
			ShareLink(item: Network.shared.baseURL.appending(path: milestonePath))
		}
	}
}
