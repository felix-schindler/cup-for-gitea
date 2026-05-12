//
//  SubscriptionsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct SubscriptionsLoader: View {
	private let icon = Icons.starred.rawValue
	@State private var repos: Result<[Components.Schemas.Repository], Error>?

	private func load() async {
		do {
			let repos = try await Network.shared.client.userCurrentListSubscriptions().ok.body.json
			self.repos = .success(repos)
		} catch {
			print(error, error.localizedDescription)
			self.repos = .failure(error)
		}
	}

	var body: some View {
		List {
			Section {
				Label(
					"Gitea Web provides two tabs, \"Subscriptions\" and \"Watching\", however the REST API only returns watched repositories, not the subscription items.",
					systemImage: "exclamationmark.triangle"
				)
				.foregroundStyle(.foreground, .yellow)
			}
			if let repos {
				switch repos {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no watched repositories", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { repo in
							SmallRepoView(repo)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading watched repositories", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Subscriptions")
	}
}

#Preview {
	NavigationStack {
		SubscriptionsLoader()
	}
}
