//
//  LabelsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI

struct LabelsLoader: View {
	let owner: String
	let repo: String

	@State private var results: Result<[Components.Schemas.Label], Error>?
	private let icon = Icons.topics.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client
				.issueListLabels(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
			self.results = .success(results)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		LoadableList(
			result: results,
			id: \.id,
			loadingText: "Loading Labels",
			emptyText: "There are no labels",
			icon: icon,
			load: load
		) { label in
			SmallLabelView(label: label)
		}
		.navigationTitle("Labels")
	}
}

#Preview {
	NavigationStack {
		LabelsLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
