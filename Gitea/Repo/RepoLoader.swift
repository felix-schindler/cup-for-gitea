//
//  RepoLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

/// Loads a repository by owner and name, e.g. from a pasted link.
struct RepoLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<Components.Schemas.Repository>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client.repoGet(path: .init(owner: owner, repo: repo)).ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading repository", systemImage: Icons.repositories.rawValue)
			case .loaded(let repo), .loadingMore(let repo), .failedMore(let repo, _):
				FullRepoView(repo)
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}
	}
}
