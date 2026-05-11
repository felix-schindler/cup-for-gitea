//
//  RepoSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct RepoSearchLoader: View {
	@Binding var search: String
	@State private var results: Result<[Components.Schemas.Repository], Error>? = nil
	private let icon = Icons.repositories.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client.repoSearch(.init(query: .init(q: search))).ok.body.json.data
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
						NoContentView("There are no repositories", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { repo in
							SmallRepoView(repo)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading repositories", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}
	}
}
