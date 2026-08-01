//
//  RepoWorktimeLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 10.06.26.
//

import SwiftUI

struct RepoWorktimeLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<[Components.Schemas.TrackedTime]>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client
					.repoTrackedTimes(path: .init(owner: owner, repo: repo))
					.ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView("Loading work times", systemImage: "clock")
			case .loaded(let entries), .loadingMore(let entries), .failedMore(let entries, _):
				if entries.isEmpty {
					NoContentView("There are no tracked times", systemImage: "clock")
				} else {
					summarySection(entries)
					contributorSections(entries)
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.navigationTitle("Worktime")
	}

	private var totalTime: Int64 {
		if case .loaded(let entries) = state {
			entries.reduce(0) { $0 + ($1.time ?? 0) }
		} else {
			0
		}
	}

	@ViewBuilder
	private func summarySection(_ entries: [Components.Schemas.TrackedTime]) -> some View {
		Section {
			LabeledContent("Total entries", value: "\(entries.count)")
			LabeledContent("Total time", value: TimeFormatter.shared.format(totalTime))
		}
	}

	@ViewBuilder
	private func contributorSections(_ entries: [Components.Schemas.TrackedTime]) -> some View {
		let grouped = Dictionary(grouping: entries, by: { $0.userName ?? "" })
		let sorted = grouped.sorted { $0.key < $1.key }

		ForEach(sorted, id: \.key) { userName, userEntries in
			let userTotal = userEntries.reduce(0) { $0 + ($1.time ?? 0) }
			Section {
				ForEach(userEntries, id: \.id) { entry in
					WorktimeRow(entry: entry)
				}
			} header: {
				HStack {
					Text(userName)
					Spacer()
					Text(TimeFormatter.shared.format(userTotal))
						.foregroundStyle(.secondary)
				}
			}
		}
	}
}

struct WorktimeRow: View {
	let entry: Components.Schemas.TrackedTime

	var body: some View {
		let issue = entry.issue
		NavigationLink(destination: IssueLoader(owner: issue?.repository?.owner ?? "", repo: issue?.repository?.name ?? "", index: issue?.number ?? 0)) {
			VStack(alignment: .leading) {
				HStack {
					if let inline = try? AttributedString(markdown: (issue?.title ?? "").emojized()) {
						Text(inline)
							.lineLimit(1)
					} else {
						Text((issue?.title ?? "").emojized())
							.lineLimit(1)
					}
					Spacer()
					Text(TimeFormatter.shared.format(entry.time ?? 0))
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				Text("\(issue?.repository?.fullName ?? "")#\(issue?.number ?? 0) · \(entry.created?.toString() ?? "")")
					.font(.caption)
					.foregroundStyle(.tertiary)
			}
		}
	}
}
