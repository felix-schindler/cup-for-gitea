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

	@State private var state = LoadState<[Components.Schemas.Release]>.loading

	private func load() async {
		do {
			state = .loaded(try await Network.shared.client.repoListReleases(path: .init(owner: owner, repo: repo)).ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Releases",
			emptyText: "There are no releases",
			icon: Icons.topics.rawValue,
			load: load
		) { release in
			ReleaseView(release)
		}
		.toolbar {
			NavigationLink(destination: NewReleaseView(owner: owner, repo: repo)) {
				Label("New Release", systemImage: "plus")
			}
		}
		.navigationTitle("Releases")
	}
}
