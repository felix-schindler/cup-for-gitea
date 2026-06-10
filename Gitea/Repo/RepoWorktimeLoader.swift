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
		state = await LoadState {
			try await Network.shared.client
				.repoTrackedTimes(path: .init(owner: owner, repo: repo))
				.ok.body.json
		}
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView("Loading work times", systemImage: "clock")
			case .loaded(let entries):
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
			entries.reduce(0) { $0 + $1.time }
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
		let grouped = Dictionary(grouping: entries, by: \.userName)
		let sorted = grouped.sorted { $0.key < $1.key }

		ForEach(sorted, id: \.key) { userName, userEntries in
			let userTotal = userEntries.reduce(0) { $0 + $1.time }
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
		NavigationLink(destination: IssueLoader(owner: entry.issue.repository.owner, repo: entry.issue.repository.name, index: entry.issue.number)) {
			VStack(alignment: .leading) {
				HStack {
					if let inline = try? AttributedString(markdown: entry.issue.title.emojized()) {
						Text(inline)
							.lineLimit(1)
					} else {
						Text(entry.issue.title.emojized())
							.lineLimit(1)
					}
					Spacer()
					Text(TimeFormatter.shared.format(entry.time))
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				Text("\(entry.issue.repository.fullName)#\(entry.issue.number) · \(entry.created.toString())")
					.font(.caption)
					.foregroundStyle(.tertiary)
			}
		}
	}
}
