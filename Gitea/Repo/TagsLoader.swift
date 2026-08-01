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
		do {
			state = .loaded(try await Network.shared.client.repoListTags(path: .init(owner: owner, repo: repo)).ok.body.json)
		} catch {
			state = .failed(error)
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
				Text((tag.name ?? "").emojized())
					.font(.headline)

				VStack(alignment: .leading) {
					if let commit = tag.commit {
						HStack {
							Text(String((commit.sha ?? "").prefix(10)))
								.monospaced()
							Text(commit.created?.toString() ?? "")
						}
					}
				}
				.font(.footnote)
				.foregroundStyle(.secondary)

				if tag.message?.isNotEmpty == true {
					Text((tag.message ?? "").emojized())
				}

				if tag.tarballUrl?.isNotEmpty == true || tag.zipballUrl?.isNotEmpty == true {
					ScrollView(.horizontal) {
						HStack {
							if let zipballUrl = tag.zipballUrl, let url = URL(string: zipballUrl) {
								Link(
									destination: url,
									label: {
										Label("ZIP", systemImage: "doc.zipper")
									})
							}

							if let tarballUrl = tag.tarballUrl, let url = URL(string: tarballUrl) {
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
