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

	func load() async {
		state = await LoadState {
			let packages = try await Network.shared.client.listPackages(
				path: .init(owner: owner),
				query: .init(page: 1, limit: 7)
			).ok.body.json
			return packages.filter { $0.repository?.name == repo }
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading packages",
			emptyText: "There are no packages",
			icon: Icons.packages.rawValue,
			load: load
		) { pkg in
			SmallPackageView(pkg)
		}
		.navigationTitle("Packages")
	}
}
