//
//  ActivityLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 16.06.26.
//

import SwiftUI

struct ActivityLoader: View {
	enum Context {
		case home
		case user(String)
		case org(String)
	}

	let context: Context

	@State private var results: [Components.Schemas.Activity] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1
	@State private var heatmap: [Components.Schemas.UserHeatmapData]?
	@State private var heatmapError: Error?
	@State private var userLogin: String?

	private let defaultLimit = 20

	private var showHeatmap: Bool {
		if case .org = context { return false }
		return true
	}

	private var showActor: Bool {
		if case .user = context { return false }
		return true
	}

	var body: some View {
		List {
			if results.isEmpty && isLoadingPage {
				LoadingView("Loading activity", systemImage: Icons.activity.rawValue)
			} else if results.isEmpty {
				if let error {
					FailedView(error)
				} else {
					Section {
						NoContentView("No recent activity", systemImage: Icons.activity.rawValue)
					}
				}
			} else {
				if showHeatmap, let heatmap, heatmap.isNotEmpty {
					ContributionGraphView(data: heatmap)
						.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
						.listRowBackground(Color.clear)
				}

				Section {
					ForEach(results, id: \.id) { activity in
						ActivityView(activity: activity, showActor: showActor)
							.onAppear {
								if activity.id == results.last?.id, hasMorePages {
									Task { await loadNextPage() }
								}
							}
					}
					if isLoadingPage {
						LoadingView("Loading more", systemImage: Icons.activity.rawValue)
					} else if let error {
						FailedView(error)
					}
				}
			}
		}
		.task {
			await resetAndLoad()
		}
		.refreshable {
			await resetAndLoad()
		}
		.navigationTitle("Activity")
	}

	private func resetAndLoad() async {
		results = []
		error = nil
		currentPage = 1
		hasMorePages = true
		isLoadingPage = false
		userLogin = nil
		if showHeatmap {
			heatmap = nil
			heatmapError = nil
		}
		await loadNextPage()
	}

	private func loadNextPage() async {
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		defer { isLoadingPage = false }
		do {
			let activities: [Components.Schemas.Activity]
			switch context {
			case .home:
				if currentPage == 1 {
					let user = try await Network.shared.client.userGetCurrent().ok.body.json
					userLogin = user.login
					await loadHeatmap(username: user.login)
				}
				guard let login = userLogin else { return }
				activities = try await Network.shared.client.userListActivityFeeds(
					.init(
						path: .init(username: login),
						query: .init(page: currentPage, limit: defaultLimit)
					)
				).ok.body.json
			case .user(let username):
				if currentPage == 1 {
					await loadHeatmap(username: username)
				}
				activities = try await Network.shared.client.userListActivityFeeds(
					.init(
						path: .init(username: username),
						query: .init(page: currentPage, limit: defaultLimit)
					)
				).ok.body.json
			case .org(let org):
				activities = try await Network.shared.client.orgListActivityFeeds(
					.init(
						path: .init(org: org),
						query: .init(page: currentPage, limit: defaultLimit)
					)
				).ok.body.json
			}
			if Task.isCancelled { return }
			results.append(contentsOf: activities)
			if activities.count < defaultLimit {
				hasMorePages = false
			} else {
				currentPage += 1
			}
		} catch {
			if Task.isCancelled { return }
			self.error = error
		}
	}

	private func loadHeatmap(username: String) async {
		do {
			heatmap = try await Network.shared.client.userGetHeatmapData(.init(path: .init(username: username))).ok.body.json
		} catch {
			heatmapError = error
		}
	}
}
