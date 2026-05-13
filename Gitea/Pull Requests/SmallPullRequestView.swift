//
//  SmallPullRequestView.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct SmallPullRequestView: View {
	private let pullRequest: Components.Schemas.PullRequest

	init(_ pullRequest: Components.Schemas.PullRequest) {
		self.pullRequest = pullRequest
	}

	var body: some View {
		NavigationLink(destination: PullRequestLoader(owner: pullRequest.base.repo.owner.login, repo: pullRequest.base.repo.name, index: pullRequest.number)) {
			VStack(alignment: .leading) {
				HStack(spacing: 5) {
					StateIconView(.pull, pullRequest.merged ? .merged : (pullRequest.state == .open ? .open : .closed))
					ScrollView(.horizontal, showsIndicators: false) {
						Text("\(pullRequest.base.repo.fullName)#\(pullRequest.number)")
							.foregroundStyle(.secondary)
					}
					if pullRequest.isLocked {
						Image(systemName: "lock")
					}
					Spacer()
					Text(pullRequest.createdAt.toString())
				}.font(.footnote)

				if let inline = try? AttributedString(markdown: pullRequest.title.emojized()) {
					Text(inline)
				} else {
					Text(pullRequest.title.emojized())
				}

				HStack(spacing: 5) {
					ScrollView(.horizontal, showsIndicators: false) {
						SmallUserView(pullRequest.user)
					}
					Spacer()
					Image(systemName: Icons.comments.rawValue)
						.font(.footnote)
						.foregroundStyle(.foreground)
					Text("\(pullRequest.comments)")
						.font(.footnote)
				}
			}
		}
	}
}
