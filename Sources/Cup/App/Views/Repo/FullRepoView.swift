//
//  RepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import GiteaAPI
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
							if let openIssuesCount = repo.openIssuesCount {
								Spacer()
								Text("\(openIssuesCount)")
							}
						}
					},
					icon: {
						Image(systemName: Icons.issues.rawValue)
					})

				Label(
					title: {
						HStack {
							Text("Pull Requests")
							if let openPrCounter = repo.openPrCounter {
								Spacer()
								Text("\(openPrCounter)")
							}
						}
					},
					icon: {
						Image(systemName: Icons.issues.rawValue)
					})
			}
		}
	}
}
