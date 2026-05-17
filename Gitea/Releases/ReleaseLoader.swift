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
		LoadableList(
			result: releases,
			id: \.id,
			loadingText: "Loading Releases",
			emptyText: "There are no releases",
			icon: Icons.topics.rawValue,
			load: load
		) { release in
			ReleaseView(release)
		}
		.navigationTitle("Releases")
	}
}
