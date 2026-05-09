//
//  RepoHeader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct HeaderRepoView: View {
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	var body: some View {
		VStack {
			if repo.name.isNotEmpty {
				Text(repo.name)
			}

			HStack {
				if repo.owner.fullName.isNotEmpty {
					Text(repo.owner.fullName)
				} else {
					Text(repo.owner.login)
				}

				Text("\(repo.starsCount)")
				Text("\(repo.forksCount)")
			}
		}
	}
}
