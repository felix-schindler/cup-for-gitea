//
//  PullRequestLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

struct PullRequestLoader: View {
	let owner: String
	let repo: String
	let index: Int64

	@State private var state = LoadState<Components.Schemas.PullRequest>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.repoGetPullRequest(.init(path: .init(owner: owner, repo: repo, index: index)))
				.ok.body.json
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading Pull Request", systemImage: Icons.pull_requests.rawValue)
			case .loaded(let pr), .loadingMore(let pr), .failedMore(let pr, _):
				IssueView(pr)
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}.navigationTitle("Pull Request")
			.navigationBarTitleDisplayMode(.inline)
	}
}
