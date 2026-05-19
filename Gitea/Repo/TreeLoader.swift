//
//  TreeLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import Foundation
import SwiftUI

struct TreeLoader: View {
	let owner: String
	let repo: String
	let folderPath: String?

	@State private var ref: String
	@State private var branches: [Components.Schemas.Branch]?
	@State private var state = LoadState<[Components.Schemas.ContentsResponse]>.loading

	init(owner: String, repo: String, ref: String, folderPath: String? = nil) {
		self.owner = owner
		self.repo = repo
		self.folderPath = folderPath
		self._ref = State(initialValue: ref)
	}

	private func load() async {
		state = await LoadState {
			let response = try await Network.shared.client.repoGetContentsExt(
				path: .init(owner: owner, repo: repo, filepath: folderPath ?? "."),
				query: .init(ref: ref)
			).ok.body.json
			if let dirContents = response.dirContents {
				return dirContents
			} else if let fileContents = response.fileContents {
				return [fileContents]
			}
			return []
		}
	}

	private func loadBranches() async {
		branches = try? await Network.shared.client.repoListBranches(
			path: .init(owner: owner, repo: repo)
		).ok.body.json
	}

	var body: some View {
		List {
			if folderPath == nil {
				Section {
					if let branches {
						HStack {
							Text("Branch")
							Picker("", selection: $ref) {
								ForEach(branches, id: \.name) { branch in
									Text(branch.name).tag(branch.name)
								}
							}
							.pickerStyle(.menu)
							.onChange(of: ref) { _, _ in
								Task { await load() }
							}
						}
					}
				}
			}

			Section(folderPath ?? "Files") {
				switch state {
				case .loading:
					LoadingView("Loading files", systemImage: "folder")
				case .loaded(let entries):
					if entries.isEmpty {
						NoContentView("No files", systemImage: "folder")
					} else {
						ForEach(entries, id: \.path) { entry in
							if entry._type == "dir" {
								NavigationLink(
									destination: TreeLoader(
										owner: owner,
										repo: repo,
										ref: ref,
										folderPath: entry.path
									)
								) {
									Label(entry.name, systemImage: "folder")
								}
							} else {
								NavigationLink(
									destination: FileLoader(
										owner: owner,
										repo: repo,
										filePath: entry.path,
										ref: ref
									)
								) {
									Label(entry.name, systemImage: "doc.text")
								}
							}
						}
					}
				case .failed(let failure):
					FailedView(failure)
				}
			}
		}
		.task {
			await load()
			if folderPath == nil {
				await loadBranches()
			}
		}
		.refreshable {
			await load()
			if folderPath == nil {
				await loadBranches()
			}
		}
		.navigationTitle("Files")
	}
}
