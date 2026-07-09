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

	@State private var state = LoadState<[Components.Schemas.Activity]>.loading
	@State private var paging = Paging()
	@State private var heatmap: [Components.Schemas.UserHeatmapData]?
	@State private var heatmapError: Error?
	@State private var userLogin: String?

	private let defaultLimit = 7

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
			switch state {
			case .loading:
				LoadingView("Loading activity", systemImage: Icons.activity.rawValue)
			case .failed(let error):
				FailedView(error)
			case .loaded(let data), .loadingMore(let data), .failedMore(let data, _):
				if data.isEmpty {
					if case .failedMore(_, let error) = state {
						FailedView(error)
					} else {
						NoContentView("No recent activity", systemImage: Icons.activity.rawValue)
					}
				} else {
					if showHeatmap, let heatmap, heatmap.isNotEmpty {
						ContributionGraphView(data: heatmap)
							.listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
							.listRowBackground(Color.clear)
					}

					Section {
						ForEach(data, id: \.id) { activity in
							ActivityView(activity: activity, showActor: showActor)
								.onAppear {
									if activity.id == data.last?.id, paging.hasMore {
										Task { await loadNextPage() }
									}
								}
						}
						if case .loadingMore = state {
							LoadingView("Loading more", systemImage: Icons.activity.rawValue)
						} else if case .failedMore(_, let error) = state {
							FailedView(error)
						}
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
		guard !paging.isLoading else { return }
		state = .loading
		paging.reset()
		userLogin = nil
		if showHeatmap {
			heatmap = nil
			heatmapError = nil
		}
		await loadNextPage()
	}

	private func loadNextPage() async {
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit) { [self] page in
			switch context {
			case .home:
				if page == 1 {
					let user = try await Network.shared.client.userGetCurrent().ok.body.json
					userLogin = user.login
					await loadHeatmap(username: user.login)
				}
				guard let login = userLogin else { return [] }
				return try await Network.shared.client.userListActivityFeeds(
					.init(
						path: .init(username: login),
						query: .init(page: page, limit: defaultLimit)
					)
				).ok.body.json
			case .user(let username):
				if page == 1 {
					await loadHeatmap(username: username)
				}
				return try await Network.shared.client.userListActivityFeeds(
					.init(
						path: .init(username: username),
						query: .init(page: page, limit: defaultLimit)
					)
				).ok.body.json
			case .org(let org):
				return try await Network.shared.client.orgListActivityFeeds(
					.init(
						path: .init(org: org),
						query: .init(page: page, limit: defaultLimit)
					)
				).ok.body.json
			}
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
