//
//  NamespaceLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct NamespaceLoader: View {
	let owner: String
	@State private var state = LoadState<Components.Schemas.Organization>.loading

	init(_ owner: String) {
		self.owner = owner
	}

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.orgGet(path: .init(org: owner)).ok.body.json
		}
	}

	var body: some View {
		VStack {
			switch state {
			case .loading:
				LoadingView("Loading namespace", systemImage: "person.3")
			case .loaded(let org), .loadingMore(let org), .failedMore(let org, _):
				OrgView(org: org)
			case .failed:
				UserLoader(username: owner)
			}
		}.task {
			await load()
		}
	}
}

#Preview {
	VStack(alignment: .leading) {
		NamespaceLoader("Tanuki")
		NamespaceLoader("felix-schindler")
	}
}
