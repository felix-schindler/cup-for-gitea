//
//  UserOrgLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct UserOrgLoader: View {
	let username: String?
	@State private var state = LoadState<[Components.Schemas.Organization]>.loading
	@State private var paging = Paging()

	private let defaultLimit = 7

	init(_ username: String? = nil) {
		self.username = username
	}

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
			if let username {
				return try await Network.shared.client.orgListUserOrgs(.init(path: .init(username: username), query: .init(page: page, limit: defaultLimit))).ok.body.json
			}
			return try await Network.shared.client.orgListCurrentUserOrgs(.init(query: .init(page: page, limit: defaultLimit))).ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading organizations",
			emptyText: "There are no organizations",
			icon: Icons.organizations.rawValue,
			load: { await resetAndLoad() },
			loadMore: { await loadNextPage() },
			hasMorePages: paging.hasMore
		) { org in
			SmallOrgView(org)
		}
		.navigationTitle("Organizations")
	}
}

#Preview {
	NavigationStack {
		UserOrgLoader("felix-schindler")
	}
}
