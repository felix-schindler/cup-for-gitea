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

	private func load() async {
		do {
			let results = try await Network.shared.client.userSearch(.init(query: .init(q: search))).ok.body.json.data
			self.results = .success(results)
		} catch {
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
						NoContentView("There no users", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { user in
							SmallUserView(user)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading users", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}
	}
}
