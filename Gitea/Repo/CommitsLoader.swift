//
//  CommitsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import SwiftUI

struct CommitsLoader: View {
	let owner: String
	let repo: String

	@State private var ref: String
	@State private var branches: [Components.Schemas.Branch]?
	@State private var state = LoadState<[Components.Schemas.Commit]>.loading

	init(owner: String, repo: String, ref: String) {
		self.owner = owner
		self.repo = repo
		self._ref = State(initialValue: ref)
	}

	private func load() async {
		state = await LoadState {
			try await Network.shared.client.repoGetAllCommits(
				path: .init(owner: owner, repo: repo),
				query: .init(sha: ref)
			).ok.body.json
		}
	}

	private func loadBranches() async {
		branches = try? await Network.shared.client.repoListBranches(
			path: .init(owner: owner, repo: repo)
		).ok.body.json
	}

	var body: some View {
		List {
			if branches != nil {
				HStack {
					Text("On branch")
					Picker("", selection: $ref) {
						ForEach(branches!, id: \.name) { branch in
							Text(branch.name).tag(branch.name)
						}
					}
					.pickerStyle(.menu)
					.onChange(of: ref) {
						Task { await load() }
					}
				}
			}

			switch state {
			case .loading:
				LoadingView("Loading Commits", systemImage: Icons.commits.rawValue)
			case .loaded(let commits):
				if commits.isEmpty {
					NoContentView(
						"No commits on \(ref)",
						systemImage: Icons.commits.rawValue,
						description: "Push a commit to see it here"
					)
				} else {
					Section {
						ForEach(commits, id: \.sha) { commit in
							NavigationLink(
								destination: CommitDetailView(owner: owner, repo: repo, commit: commit)
							) {
								CommitRow(commit: commit)
							}
							.swipeActions {
								if let url = URL(string: commit.htmlUrl) {
									ShareLink(item: url)
								}
							}
						}
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}
		.task {
			await load()
			await loadBranches()
		}
		.refreshable {
			await load()
			await loadBranches()
		}
		.navigationTitle("Commits")
	}
}

private struct CommitRow: View {
	let commit: Components.Schemas.Commit

	var body: some View {
		VStack(alignment: .leading) {
			Text(commit.commit.message.emojized())
				.fontWeight(.medium)

			HStack {
				Text(commit.sha.prefix(10))
					.monospaced()
				Text(commit.created.toString())
			}.font(.footnote)

			HStack {
				if let author = commit.author {
					Text("Authored by \(author.login)")
					if author.fullName.isNotEmpty {
						Text("(\(author.fullName))")
					}
				} else {
					Text("Authored by \(commit.commit.author.email)")
					if commit.commit.author.name.isNotEmpty {
						Text("(\(commit.commit.author.name))")
					}
				}
			}
			.font(.footnote)
			.foregroundStyle(.secondary)
		}
	}
}

private struct CommitDetailView: View {
	let owner: String
	let repo: String
	let commit: Components.Schemas.Commit

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading, spacing: 8) {
					Text(commit.commit.message.emojized())
						.font(.title3)
						.fontWeight(.medium)

					HStack {
						StatBadge("+\(commit.stats.additions)", color: .green)
						StatBadge("-\(commit.stats.deletions)", color: .red)
						if commit.stats.total > 0 {
							StatBadge("\(commit.stats.total) total", color: .secondary)
						}
					}

					HStack {
						Text(commit.sha.prefix(10))
							.monospaced()
							.textSelection(.enabled)
						Text(commit.created.toString(timeStyle: .short))
					}.font(.footnote)

					if let author = commit.author {
						Text("Authored by \(author.login)")
						if author.fullName.isNotEmpty {
							Text("(\(author.fullName))")
						}
					} else {
						Text("Authored by \(commit.commit.author.email)")
						if commit.commit.author.name.isNotEmpty {
							Text("(\(commit.commit.author.name))")
						}
					}
				}
			}

			if commit.files.isNotEmpty {
				Section("Files") {
					ForEach(commit.files, id: \.filename) { file in
						HStack {
							Image(systemName: fileSymbol(for: file.status))
								.foregroundStyle(color(for: file.status))
							Text(file.filename)
								.font(.system(.caption, design: .monospaced))
						}
					}
				}
			}
		}
		.navigationTitle("Commit \(commit.sha.prefix(10))")
		.navigationBarTitleDisplayMode(.inline)
	}

	private func fileSymbol(for status: String?) -> String {
		switch status {
		case "added": return "plus.circle"
		case "deleted": return "minus.circle"
		case "modified": return "pencil.circle"
		case "renamed": return "arrow.right.circle"
		default: return "doc.circle"
		}
	}

	private func color(for status: String?) -> Color {
		switch status {
		case "added": return .green
		case "deleted": return .red
		case "modified": return .orange
		case "renamed": return .blue
		default: return .secondary
		}
	}
}

private struct StatBadge: View {
	let text: String
	let color: Color

	init(_ text: String, color: Color) {
		self.text = text
		self.color = color
	}

	var body: some View {
		Text(text)
			.font(.caption).fontWeight(.medium)
			.padding(.horizontal, 8)
			.padding(.vertical, 3)
			.background(color.opacity(0.15))
			.foregroundStyle(color)
			.clipShape(.capsule)
	}
}
