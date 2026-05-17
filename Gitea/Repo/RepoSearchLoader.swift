//
//  RepoSearchLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct RepoSearchLoader: View {
	@Binding var search: String
	@State private var state = LoadState<[Components.Schemas.Repository]>.loading
	private let icon = Icons.repositories.rawValue
	private let debounceNanoseconds: UInt64 = 350_000_000

	private func load(debounced: Bool = false) async {
		state = .loading
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		state = await LoadState {
			try await Network.shared.client.repoSearch(.init(query: .init(q: search))).ok.body.json.data
		}
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView("Loading repositories", systemImage: icon)
			case .loaded(let repos):
				if repos.isEmpty {
					NoContentView("There are no repositories", systemImage: icon)
				} else {
					ForEach(repos, id: \.id) { repo in
						SmallRepoView(repo)
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
