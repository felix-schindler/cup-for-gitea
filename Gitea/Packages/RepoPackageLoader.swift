//
//  RepoPackageLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.06.26.
//

import SwiftUI

struct RepoPackageLoader: View {
	let owner: String
	let repo: String
	@State private var state = LoadState<[Components.Schemas.Package]>.loading
	@State private var paging = Paging()
	// ponytail: no per-repo packages API, so raw pages are filtered client-side;
	// keep a raw cursor and skip pages until ≥ limit matches or a short page ends the list.
	@State private var rawPage = 1

	private let defaultLimit = 7

	private func resetAndLoad() async {
		guard !paging.isLoading else { return }
		paging.reset()
		rawPage = 1
		await loadNextPage(reset: true)
	}

	private func loadNextPage(reset: Bool = false) async {
		guard !paging.isLoading else { return }
		paging.isLoading = true
		defer { paging.isLoading = false }
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit, reset: reset) { _ in
			var matches: [Components.Schemas.Package] = []
			while matches.count < defaultLimit, rawPage < 10_000 {
				let raw = try await Network.shared.client.listPackages(
					path: .init(owner: owner),
					query: .init(page: rawPage, limit: defaultLimit)
				).ok.body.json
				rawPage += 1
				matches += raw.filter { $0.repository?.name == repo }
				if raw.count < defaultLimit { break }
			}
			return matches
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading packages",
			emptyText: "There are no packages",
			icon: Icons.packages.rawValue,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore
		) { pkg in
			SmallPackageView(pkg)
		}
		.navigationTitle("Packages")
	}
}
