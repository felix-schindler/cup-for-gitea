//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import GiteaAPI
import SwiftUI

struct UserReposLoader: View {
	private let icon = Icons.repositories.rawValue
	@State var repos: Result<[Components.Schemas.Repository], Error>?

	private func load() async {
		do {
			let repos = try await Network.shared.client.userCurrentListRepos().ok.body.json
			self.repos = .success(repos)
		} catch {
			print(error, error.localizedDescription)
			self.repos = .failure(error)
		}
	}

	var body: some View {
		List {
			if let repos {
				switch repos {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no Repositories", systemImage: icon)
					} else {
						ForEach(success, id: \.id!) { repo in
							SmallRepoView(repo)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Repositories", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Repositories")
	}
}
