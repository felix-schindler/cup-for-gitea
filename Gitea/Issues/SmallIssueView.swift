//
//  SmallIssueView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct SmallIssueView: View {
	private let issue: Components.Schemas.Issue

	init(_ issue: Components.Schemas.Issue) {
		self.issue = issue
	}

	var body: some View {
		NavigationLink(destination: IssueView(issue)) {
			VStack(alignment: .leading) {
				HStack(spacing: 5) {
					StateIconView(.issue, issue.state)
					ScrollView(.horizontal, showsIndicators: false) {
						Text("\(issue.repository.fullName)#\(issue.number)")
							.foregroundStyle(.secondary)
					}
					Spacer()
					Text(issue.createdAt.toString())
				}.font(.footnote)

				if let inline = try? AttributedString(markdown: issue.title.emojized()) {
					Text(inline)
				} else {
					Text(issue.title.emojized())
				}

				HStack(spacing: 5) {
					ScrollView(.horizontal, showsIndicators: false) {
						SmallUserView(issue.user)
					}
					Spacer()
					Image(systemName: "note.text")
						.font(.footnote)
						.foregroundStyle(.foreground)
					Text("\(issue.comments)")
						.font(.footnote)
				}
			}
		}
	}
}
