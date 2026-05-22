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

	@State private var state = LoadState<[Components.Schemas.Label]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.issueListLabels(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Labels",
			emptyText: "There are no labels",
			icon: Icons.topics.rawValue,
			load: load
		) { label in
			SmallLabelView(label: label)
		}
		.toolbar {
			NavigationLink(destination: NewLabelView(owner: owner, repo: repo)) {
				Label("New Label", systemImage: "plus")
			}
		}
		.navigationTitle("Labels")
	}
}

#Preview {
	NavigationStack {
		LabelsLoader(owner: "Tanuki", repo: "gitea-ios")
	}
}
