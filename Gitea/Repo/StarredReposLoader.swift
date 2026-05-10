//
//  StarredReposLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct StarredReposLoader: View {
	let username: String?
	private let icon = Icons.starred.rawValue
	@State private var repos: Result<[Components.Schemas.Repository], Error>?
	
	init(_ username: String? = nil) {
		self.username = username
	}

	private func load() async {
		do {
			var repos: [Components.Schemas.Repository]
			if let username {
				repos = try await Network.shared.client.userListStarred(path: .init(username: username)).ok.body.json
			} else {
				repos = try await Network.shared.client.userCurrentListStarred().ok.body.json
			}
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
						NoContentView("There are no starred repositories", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { repo in
							SmallRepoView(repo)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading starred Repositories", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Starred Repositories")
	}
}
