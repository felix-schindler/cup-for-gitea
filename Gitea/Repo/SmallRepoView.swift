//
//  SmallRepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct SmallRepoView: View {
	private let repo: Components.Schemas.Repository
	private let showFullName: Bool

	init(_ repo: Components.Schemas.Repository, showFullName: Bool = false) {
		self.repo = repo
		self.showFullName = showFullName
	}

	var body: some View {
		NavigationLink(
			destination: {
				FullRepoView(repo)
			},
			label: {
				HStack {
					if let url = URL(string: repo.avatarUrl) {
						AvatarImage(url, size: .small)
					}
					if showFullName {
						Text(repo.fullName)
					} else {
						Text(repo.name)
					}
					Spacer()
					if repo.fork {
						Image(systemName: Icons.forks.rawValue)
					}
					if repo.template {
						Image(systemName: "document.on.document")
					}
					if repo.mirror {
						Image(systemName: "square.stack.3d.forward.dottedline")
					}
					if repo.archived {
						Image(systemName: "archivebox")
					}
					VisibilityIcon(repo._private ? "private" : repo._internal ? "limited" : "")
				}
			})
	}
}
