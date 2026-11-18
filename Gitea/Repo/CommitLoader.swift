//
//  CommitLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

struct CommitLoader: View {
	let owner: String
	let repo: String
	let sha: String

	@State private var state = LoadState<Components.Schemas.Commit>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client.repoGetSingleCommit(
					path: .init(owner: owner, repo: repo, sha: sha)
				).ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading commit", systemImage: Icons.commits.rawValue)
			case .loaded(let commit), .loadingMore(let commit), .failedMore(let commit, _):
				CommitDetailView(owner: owner, repo: repo, commit: commit)
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}
	}
}
