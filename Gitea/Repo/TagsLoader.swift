//
//  TagsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import SwiftUI

struct TagsLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<[Components.Schemas.Tag]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.repoListTags(path: .init(owner: owner, repo: repo)).ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.name,
			loadingText: "Loading Tags",
			emptyText: "There are no tags",
			icon: Icons.topics.rawValue,
			load: load
		) { tag in
			VStack(alignment: .leading) {
				Text(tag.name.emojized())
					.font(.headline)

				VStack(alignment: .leading) {
					HStack {
						Text(tag.commit.sha.prefix(10))
							.monospaced()
						Text(tag.commit.created.toString())
					}
				}
				.font(.footnote)
				.foregroundStyle(.secondary)

				if tag.message.isNotEmpty {
					Text(tag.message.emojized())
				}

				if tag.tarballUrl.isNotEmpty || tag.zipballUrl.isNotEmpty {
					ScrollView(.horizontal) {
						HStack {
							if let url = URL(string: tag.zipballUrl) {
								Link(
									destination: url,
									label: {
										Label("ZIP", systemImage: "doc.zipper")
									})
							}

							if let url = URL(string: tag.tarballUrl) {
								Link(
									destination: url,
									label: {
										Label("TAR.GZ", systemImage: "doc.zipper")
									})
							}
						}
					}
					.controlSize(.mini)
					.buttonBorderShape(.capsule)
					.adaptiveButtonStyle()
				}
			}
		}
		.navigationTitle("Tags")
	}
}
