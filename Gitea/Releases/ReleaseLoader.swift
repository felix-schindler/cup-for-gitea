//
//  ReleaseLaoder.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct ReleaseLoader: View {
	let owner: String
	let repo: String

	@State private var releases: Result<[Components.Schemas.Release], Error>?

	private func load() async {
		do {
			let releases = try await Network.shared.client.repoListReleases(path: .init(owner: owner, repo: repo)).ok.body.json
			self.releases = .success(releases)
		} catch {
			self.releases = .failure(error)
		}
	}

	var body: some View {
		List {
			if let releases {
				switch releases {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no releases", systemImage: Icons.topics.rawValue)
					} else {
						ForEach(success, id: \.id) { release in
							ReleaseView(release)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Releases", systemImage: Icons.topics.rawValue)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Releases")
	}
}
