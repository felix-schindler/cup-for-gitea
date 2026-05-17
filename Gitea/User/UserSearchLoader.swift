//
//  UserSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct UserSearchLoader: View {
	@Binding var search: String
	@State private var state = LoadState<[Components.Schemas.User]>.loading
	private let icon = Icons.users.rawValue
	private let debounceNanoseconds: UInt64 = 350_000_000

	private func load(debounced: Bool = false) async {
		state = .loading
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		state = await LoadState {
			try await Network.shared.client.userSearch(.init(query: .init(q: search))).ok.body.json.data
		}
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView("Loading users", systemImage: icon)
			case .loaded(let users):
				if users.isEmpty {
					NoContentView("There are no users", systemImage: icon)
				} else {
					ForEach(users, id: \.id) { user in
						SmallUserView(user, avatarSize: .medium)
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}.task(id: search) {
			await load(debounced: true)
		}.refreshable {
			await load()
		}
	}
}
