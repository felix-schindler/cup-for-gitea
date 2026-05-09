//
//  RepoHeader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import GiteaAPI
import SwiftUI

struct HeaderRepoView: View {
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	var body: some View {
		VStack {
			if let name = repo.name {
				Text(name)
			}

			HStack {
				if let owner = repo.owner,
					let name = owner.fullName ?? owner.login ?? owner.loginName,
					!name.isEmpty
				{
					Text(name)
				}

				if let starsCount = repo.starsCount {
					Text("\(starsCount)")
				}

				if let forksCount = repo.forksCount {
					Text("\(forksCount)")
				}
			}
		}
	}
}
