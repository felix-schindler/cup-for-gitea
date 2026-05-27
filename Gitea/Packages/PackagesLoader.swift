//
//  PackagesLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 28.05.26.
//

import SwiftUI

struct PackagesLoader: View {
	let owner: String

	@State private var state = LoadState<[Components.Schemas.Package]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.listPackages(
				.init(path: .init(owner: owner))
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
			load: load
		) { pkg in
			SmallPackageView(pkg)
		}
		.navigationTitle("Packages")
	}
}
