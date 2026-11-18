//
//  ReleaseTagLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

struct ReleaseTagLoader: View {
	let owner: String
	let repo: String
	let tag: String

	@State private var state = LoadState<Components.Schemas.Release>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client.repoGetReleaseByTag(
					path: .init(owner: owner, repo: repo, tag: tag)
				).ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading release", systemImage: Icons.topics.rawValue)
			case .loaded(let release), .loadingMore(let release), .failedMore(let release, _):
				List {
					ReleaseView(release)
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}.navigationTitle(tag)
			.navigationBarTitleDisplayMode(.inline)
	}
}
