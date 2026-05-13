//
//  RepoPullRequestLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct RepoPullRequestsLoader: View {
	let owner: String
	let repo: String

	@State private var results: Result<[Components.Schemas.PullRequest], Error>?
	private let icon = Icons.pull_requests.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client
				.repoListPullRequests(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
			self.results = .success(results)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		List {
			if let results {
				switch results {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no pull requests", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { pr in
							SmallPullRequestView(pr)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Pull Requests", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Pull Requests")
	}
}
