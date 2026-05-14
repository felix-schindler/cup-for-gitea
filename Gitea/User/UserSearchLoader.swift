//
//  UserSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct UserSearchLoader: View {
	@Binding var search: String
	@State private var results: Result<[Components.Schemas.User], Error>? = nil
	private let icon = Icons.users.rawValue
	private let debounceNanoseconds: UInt64 = 350_000_000

	private func load(debounced: Bool = false) async {
		self.results = nil
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			let results = try await Network.shared.client.userSearch(.init(query: .init(q: search))).ok.body.json.data
			if Task.isCancelled { return }
			self.results = .success(results)
		} catch {
			if Task.isCancelled { return }
			print(error, error.localizedDescription)
			self.results = .failure(error)
		}
	}

	var body: some View {
		List {
			if let results {
				switch results {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no users", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { user in
							SmallUserView(user, avatarSize: .medium)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading users", systemImage: icon)
			}
		}.task(id: search) {
			await load(debounced: true)
		}.refreshable {
			await load()
		}
	}
}
