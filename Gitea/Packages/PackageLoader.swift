//
//  PackageLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.06.26.
//

import SwiftUI

struct PackageLoader: View {
	let owner: String
	@State private var state = LoadState<[Components.Schemas.Package]>.loading
	@State private var paging = Paging()

	private let defaultLimit = 7

	private func resetAndLoad() async {
		guard !paging.isLoading else { return }
		paging.reset()
		await loadNextPage(reset: true)
	}

	private func loadNextPage(reset: Bool = false) async {
		guard !paging.isLoading else { return }
		paging.isLoading = true
		defer { paging.isLoading = false }
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit, reset: reset) { page in
			try await Network.shared.client.listPackages(
				path: .init(owner: owner),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json
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
