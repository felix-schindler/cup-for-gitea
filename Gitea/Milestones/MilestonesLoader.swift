//
//  MilestonesLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct MilestonesLoader: View {
	let owner: String
	let repo: String

	@State private var results: Result<[Components.Schemas.Milestone], Error>?
	private let icon = Icons.milestones.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client
				.issueGetMilestonesList(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
			self.results = .success(results)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		List {
			if let results {
				switch results {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no milestones", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { milestone in
							Text(milestone.title.emojized())
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Milestones", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Milestones")
	}
}

#Preview {
	NavigationStack {
		MilestonesLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
