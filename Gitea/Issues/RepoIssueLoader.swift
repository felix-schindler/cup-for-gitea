//
//  RepoIssueLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct RepoIssueLoader: View {
	let owner: String
	let repo: String

	@State private var results: Result<[Components.Schemas.Issue], Error>?
	private let icon = Icons.issues.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client.issueListIssues(path: .init(owner: owner, repo: repo)).ok.body.json
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
						NoContentView("There are no issues", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { issue in
							SmallIssueView(issue)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Issues", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.toolbar {
			NavigationLink(destination: NewIssueView()) {
				Label("New Issue", systemImage: "plus")
			}
		}.navigationTitle("Issues")
	}
}
