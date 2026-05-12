//
//  IssueCommentsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI
import Textual

struct IssueCommentsLoader: View {
	let owner: String
	let repo: String
	let iid: Int64
	
	@State private var comments: Result<[Components.Schemas.Comment], Error>?
	
	private func load() async {
		do {
			let comments = try await Network.shared.client.issueGetComments(.init(path: .init(owner: owner, repo: repo, index: iid))).ok.body.json
			self.comments = .success(comments)
		} catch {
			self.comments = .failure(error)
		}
	}
	
	var body: some View {
		Group {
			if let comments {
				switch comments {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no comments", systemImage: Icons.comments.rawValue)
					} else {
						ForEach(success, id: \.id) { c in
							VStack(alignment: .leading) {
								HStack {
									ScrollView(.horizontal) {
										SmallUserView(c.user)
									}
									Text(c.createdAt.toString())
										.font(.footnote)
								}
								StructuredText(markdown: c.body.emojized())
									.textual.structuredTextStyle(.gitHub)
									.textual.textSelection(.enabled)
								

								if c.assets.isNotEmpty {
									ScrollView(.horizontal) {
										HStack {
											ForEach(c.assets, id: \.id) { a in
												if let url = URL(string: a.browserDownloadUrl) {
													Link(destination: url, label: {
														Label("\(a.name) (\(ByteFormatter.shared.format(a.size)))", systemImage: "square.and.arrow.down")
															.modifier {
																if #available(iOS 26.0, *) {
																	$0.labelIconToTitleSpacing(5)
																}
															}
													})
													.controlSize(.mini)
													.buttonBorderShape(.capsule)
													.modifier {
														if #available(iOS 26.0, *) {
															$0.buttonStyle(.glass)
														} else {
															$0.buttonStyle(.bordered)
														}
													}
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
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading comments", systemImage: Icons.comments.rawValue)
			}
		}.task {
			await load()
		}
	}
}

#Preview {
	NavigationStack {
		List {
			IssueCommentsLoader(owner: "tanuki", repo: "gitea-ios", iid: 6)
		}
	}
}
