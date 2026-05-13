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

	@State private var result: Result<Components.Schemas.PullRequest, Error>?
	private let icon = Icons.pull_requests.rawValue

	private func load() async {
		do {
			let pr = try await Network.shared.client
				.repoGetPullRequest(.init(path: .init(owner: owner, repo: repo, index: index)))
				.ok.body.json
			self.result = .success(pr)
		} catch {
			self.result = .failure(error)
		}
	}

	var body: some View {
		Group {
			if let result {
				switch result {
				case .success(let pr):
					PullRequestView(pr)
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Pull Request", systemImage: icon)
			}
		}.task {
			await load()
		}.navigationTitle("Pull Request")
			.navigationBarTitleDisplayMode(.inline)
	}
}
