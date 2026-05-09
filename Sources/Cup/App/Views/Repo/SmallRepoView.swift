//
//  SmallRepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import GiteaAPI
import SwiftUI

struct SmallRepoView: View {
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	var body: some View {
		NavigationLink(
			destination: {
				FullRepoView(repo)
			},
			label: {
				VStack(alignment: .leading) {
					if let name = repo.name {
						Text(name)
					}
				}
			})
	}
}
