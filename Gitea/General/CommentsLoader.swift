//
//  CommentsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI
import Textual

struct CommentsLoader: View {
	let owner: String
	let repo: String
	let iid: Int64
	var refreshID: Int = 0

	@State private var state = LoadState<[Components.Schemas.Comment]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.issueGetComments(.init(path: .init(owner: owner, repo: repo, index: iid)))
				.ok.body.json
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading comments", systemImage: Icons.comments.rawValue)
			case .loaded(let comments), .loadingMore(let comments), .failedMore(let comments, _):
				if comments.isEmpty {
					NoContentView("There are no comments", systemImage: Icons.comments.rawValue)
				} else {
					ForEach(comments, id: \.id) { c in
						VStack(alignment: .leading) {
							HStack {
								if let user = c.user {
									ScrollView(.horizontal, showsIndicators: false) {
										SmallUserView(user)
									}
								} else {
									Spacer()
								}
								Text(c.createdAt.toString())
									.font(.footnote)
							}
							StructuredText(markdown: c.body.emojized())
								.textual.structuredTextStyle(.gitHub)
								.textual.textSelection(.enabled)

							if c.assets.isNotEmpty {
								ScrollView(.horizontal, showsIndicators: false) {
									HStack {
										ForEach(c.assets, id: \.id) { a in
											if let url = URL(string: a.browserDownloadUrl) {
												Link(
													destination: url,
													label: {
														Label("\(a.name) (\(ByteFormatter.shared.format(a.size)))", systemImage: "square.and.arrow.down")
															.modifier {
																if #available(iOS 26.0, *) {
																	$0.labelIconToTitleSpacing(5)
																}
															}
													}
												)
												.controlSize(.mini)
												.buttonBorderShape(.capsule)
												.adaptiveButtonStyle()
											}
										}
									}
								}
							}
						}.swipeActions {
							if let url = URL(string: c.htmlUrl) {
								ShareLink(item: url)
							}
						}
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}.task(id: refreshID) {
			await load()
		}
	}
}

#Preview {
	NavigationStack {
		List {
			CommentsLoader(owner: "tanuki", repo: "gitea-ios", iid: 6)
		}
	}
}
