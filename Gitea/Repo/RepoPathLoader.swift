//
//  RepoPathLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

/// Resolves a `/src/branch/…` link: a directory opens the file browser, a file opens the preview.
struct RepoPathLoader: View {
	let owner: String
	let repo: String
	let ref: String
	let path: String

	@State private var isDirectory: Bool?

	private func load() async {
		let response = try? await Network.shared.client.repoGetContentsExt(
			path: .init(owner: owner, repo: repo, filepath: path),
			query: .init(ref: ref)
		).ok.body.json
		isDirectory = response?.fileContents == nil
	}

	var body: some View {
		Group {
			if let isDirectory {
				if isDirectory {
					TreeLoader(owner: owner, repo: repo, ref: ref, folderPath: path)
				} else {
					FileLoader(owner: owner, repo: repo, filePath: path, ref: ref)
				}
			} else {
				LoadingView("Loading path", systemImage: "folder")
			}
		}.task {
			await load()
		}
	}
}
