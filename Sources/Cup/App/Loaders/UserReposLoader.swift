//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import GiteaAPI
import SwiftUI

struct UserReposLoader: View {
	@State var repos: Result<[Components.Schemas.Repository], Error>?

	private func loadRepos() async {
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
					ForEach(success, id: \.id!) { repo in
						SmallRepoView(repo)
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Repositories", systemImage: "app.gift.fill")
			}
		}.onAppear {
			Task {
				await loadRepos()
			}
		}.navigationTitle("Repositories")
	}
}
