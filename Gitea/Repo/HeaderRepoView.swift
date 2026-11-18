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
	@State private var starred = false
	@State private var stars: Int64
	@State private var forks: Int64
	@State private var error: Error?
	@State private var forkedRepo: Components.Schemas.Repository?
	private let repo: Components.Schemas.Repository

	private var owner: String { repo.owner?.login ?? "" }
	private var repoName: String { repo.name ?? "" }

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
		_stars = State(initialValue: repo.starsCount ?? 0)
		_forks = State(initialValue: repo.forksCount ?? 0)
	}

	private func load() async {
		if let langs = try? await Network.shared.client.repoGetLanguages(
			path: .init(owner: owner, repo: repoName)
		).ok.body.json {
			self.langs = langs.additionalProperties
		}

		if case .noContent? = try? await Network.shared.client.userCurrentCheckStarring(
			path: .init(owner: owner, repo: repoName)
		) {
			starred = true
		}
	}

	private func setStarred(_ value: Bool) async {
		do {
			if value {
				_ = try await Network.shared.client.userCurrentPutStar(
					path: .init(owner: owner, repo: repoName)
				).noContent
			} else {
				_ = try await Network.shared.client.userCurrentDeleteStar(
					path: .init(owner: owner, repo: repoName)
				).noContent
			}
			starred = value
			stars = max(0, stars + (value ? 1 : -1))
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			HapticFeedback.notify(.error)
		}
	}

	private func fork() async {
		do {
			forkedRepo = try await Network.shared.client.createFork(
				path: .init(owner: owner, repo: repoName)
			).accepted.body.json
			forks += 1
			HapticFeedback.notify(.success)
		} catch {
			self.error = error
			HapticFeedback.notify(.error)
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
				if let avatarUrl = repo.avatarUrl, let url = URL(string: avatarUrl) {
					AvatarImage(url, size: .medium)
				}

				Text(repo.name ?? "")
					.font(.title)
					.fontWeight(.bold)
				Spacer()

				if repo._private == true {
					Image(systemName: "lock")
				} else if repo._internal == true {
					Image(systemName: "network.badge.shield.half.filled")
				} else {
					Image(systemName: "network")
				}
			}

			if let description = repo.description?.emojized(), description.isNotEmpty {
				Text(description)
			}

			HStack {
				if repo.topics?.isNotEmpty == true {
					ScrollView(.horizontal, showsIndicators: false) {
						HStack {
							Image(systemName: Icons.topics.rawValue)
							ForEach(repo.topics ?? [], id: \.self) { topic in
								NavigationLink(
									destination: RepoSearchLoader(context: .search, search: topic, limitToTopic: true)
								) {
									Text(topic)
								}
								.controlSize(.mini)
								.buttonBorderShape(.capsule)
								.adaptiveButtonStyle()
							}
						}
					}
				}
			}.font(.footnote)

			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					if repo.website?.isNotEmpty == true, let website = repo.website, let url = URL(string: website) {
						Link(website, destination: url)
							.tint(.accentColor)
							.adaptiveButtonStyle()
							.controlSize(.mini)
					}

					if repo.licenses?.isNotEmpty == true {
						ForEach(repo.licenses ?? [], id: \.self) { license in
							PillView(verbatim: license)
						}
					}

					if let size = repo.size, size > 0 {
						PillView(verbatim: ByteFormatter.shared.format(size * 1024))
					}

					PillView(verbatim: repo.createdAt?.toString() ?? "")
				}.font(.footnote)
			}

			ScrollView(.horizontal, showsIndicators: false) {
				HStack {
					if let owner = repo.owner {
						SmallUserView(owner)
					}
					AsyncButton(action: { await setStarred(!starred) }, role: nil) {
						PillView(
							verbatim: "\(stars)",
							systemImage: starred ? "star.fill" : Icons.starred.rawValue
						)
					}
					.buttonStyle(.plain)
					.accessibilityLabel(starred ? "Unstar repository" : "Star repository")

					AsyncButton(action: { await fork() }, role: nil) {
						PillView(verbatim: "\(forks)", systemImage: Icons.forks.rawValue)
					}
					.buttonStyle(.plain)
					.accessibilityLabel("Fork repository")

					PillView(verbatim: "\(repo.watchersCount ?? 0)", systemImage: Icons.watchers.rawValue)
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
		}.navigationDestination(item: $forkedRepo) { repo in
			FullRepoView(repo)
		}.alert(
			"Error",
			isPresented: Binding(
				get: { error != nil },
				set: { if !$0 { error = nil } }
			)
		) {
			Button("OK", role: .cancel) {}
		} message: {
			if let error {
				Text(error.localizedDescription)
			}
		}
	}
}
