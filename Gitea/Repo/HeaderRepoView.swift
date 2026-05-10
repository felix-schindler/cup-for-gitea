//
//  RepoHeader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import Charts
import SwiftUI

struct LanguageUsage: Identifiable, Hashable {
	let id = UUID()
	let name: String
	let lines: Int64
	let totalLines: Int64
	var percent: Double { Double(lines) / Double(totalLines) * 100 }
}

struct HeaderRepoView: View {
	@State var langs: [String: Swift.Int64]?
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	private func load() async {
		if let langs = try? await Network.shared.client.repoGetLanguages(path: .init(owner: repo.owner.login, repo: repo.name)).ok.body.json {
			self.langs = langs.additionalProperties
		}
	}

	private func chartData(_ langs: [String: Swift.Int64]?) -> [LanguageUsage] {
		guard let dict = langs, !dict.isEmpty else { return [] }
		let total = dict.values.reduce(0, +)
		return
			dict
			.map { LanguageUsage(name: $0.key, lines: $0.value, totalLines: total) }
			.sorted { $0.percent > $1.percent }
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			HStack {
				if repo.avatarUrl.isNotEmpty,
					let avatarUrl = URL(string: repo.avatarUrl)
				{
					AvatarImage(avatarUrl, size: .medium)
					Spacer()
				} else if repo.owner.avatarUrl.isNotEmpty,
					let avatarUrl = URL(string: repo.owner.avatarUrl)
				{
					AvatarImage(avatarUrl, size: .medium)
					Spacer()
				}
				Text(repo.name)
					.font(.title)
					.fontWeight(.bold)
				Spacer()

				if repo._private {
					Image(systemName: "lock")
				} else if repo._internal {
					Image(systemName: "network.badge.shield.half.filled")
				} else {
					Image(systemName: "network")
				}
			}

			if repo.description.isNotEmpty {
				Text(repo.description.emojized())
			}

			HStack {
				if repo.topics.isNotEmpty {
					ScrollView(.horizontal) {
						HStack {
							Image(systemName: Icons.topics.rawValue)
							ForEach(repo.topics, id: \.self) { topic in
								PillView(topic)
							}
						}
					}
				}
			}.font(.footnote)

			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					if repo.website.isNotEmpty, let url = URL(string: repo.website) {
						Link(repo.website, destination: url)
							.tint(.accentColor)
							.buttonStyle(.bordered)
							.controlSize(.mini)
					}

					if repo.licenses.isNotEmpty {
						ForEach(repo.licenses, id: \.self) { license in
							PillView(license)
						}
					}

					if repo.size > 0 {
						PillView(ByteFormatter.shared.format(repo.size))
					}

					PillView(repo.createdAt.toString())
				}.font(.footnote)
			}

			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					SmallUserView(repo.owner, showAvatar: repo.avatarUrl.isNotEmpty)  // TODO: Handle groups
					PillView("\(repo.starsCount)", systemImage: Icons.starred.rawValue)
					PillView("\(repo.forksCount)", systemImage: Icons.forks.rawValue)
					PillView("\(repo.watchersCount)", systemImage: Icons.watchers.rawValue)
				}
			}

			if let langs, !langs.isEmpty {
				Chart {
					ForEach(chartData(langs), id: \.self) { language in
						BarMark(
							x: .value("Percent", language.percent)
						).foregroundStyle(
							by: .value("Language", language.name)
						)
					}
				}
				.chartXAxis(.hidden)
				.chartPlotStyle { plotArea in
					plotArea.frame(height: 10)
				}
			}
		}.task {
			await load()
		}
	}
}
