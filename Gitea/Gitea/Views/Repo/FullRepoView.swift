//
//  RepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct FullRepoView: View {
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	var body: some View {
		List {
			Section {
				HeaderRepoView(repo)
			}

			Section {
				Label(
					title: {
						HStack {
							Text("Issues")
							Spacer()
							Text("\(repo.openIssuesCount)")
						}
					},
					icon: {
						Image(systemName: Icons.issues.rawValue)
					})

				Label(
					title: {
						HStack {
							Text("Pull Requests")
							Spacer()
							Text("\(repo.openPrCounter)")
						}
					},
					icon: {
						Image(systemName: Icons.issues.rawValue)
					})
			}
		}
	}
}
