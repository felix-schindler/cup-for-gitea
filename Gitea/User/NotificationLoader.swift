//
//  NotificationLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI
import Textual

enum StatusChange: String {
	case read = "read"
	case unread = "unread"
	case pinned = "pinned"

}

struct NotificationLoader: View {
	private let icon = Icons.notifications.rawValue
	@State var showAll = false
	@State private var state = LoadState<[Components.Schemas.NotificationThread]>.loading
	@State private var paging = Paging()

	private let defaultLimit = 7

	private func resetAndLoad() async {
		guard !paging.isLoading else { return }
		paging.reset()
		await loadNextPage(reset: true)
	}

	private func loadNextPage(reset: Bool = false) async {
		guard !paging.isLoading else { return }
		paging.isLoading = true
		defer { paging.isLoading = false }
		(state, paging) = await paging.nextPage(state: state, limit: defaultLimit, reset: reset) { page in
			try await Network.shared.client.notifyGetList(.init(query: .init(all: showAll, page: page, limit: defaultLimit))).ok.body.json
		}
	}

	private func mark(_ id: Int64, status: StatusChange) async throws {
		_ = try await Network.shared.client.notifyReadThread(.init(path: .init(id: String(id)), query: .init(toStatus: status.rawValue))).resetContent.body.json
	}

	private func applyStatusChange(id: Int64, status: StatusChange) {
		guard let current = state.value else { return }
		let shouldRemove: Bool
		switch status {
		case .read, .pinned:
			shouldRemove = showAll == false
		case .unread:
			shouldRemove = showAll == true
		}

		guard shouldRemove else { return }
		let updated = current.filter { $0.id != id }
		state = .loaded(updated)
	}

	var body: some View {
		List {
			Section {
				Picker("Show", selection: $showAll) {
					Text("Unread").tag(false)
					Text("Read").tag(true)
				}.onChange(of: showAll) {
					Task {
						await resetAndLoad()
					}
				}.pickerStyle(.segmented)
			}

			Section {
				switch state {
				case .loading:
					LoadingView("Loading user notification thread", systemImage: icon)
				case .loaded(let data), .loadingMore(let data), .failedMore(let data, _):
					if data.isEmpty {
						if case .failedMore(_, let error) = state {
							FailedView(error)
						} else {
							NoContentView("All caught up!", systemImage: icon, description: "No unread notifications.")
						}
					} else {
						ForEach(data, id: \.id) { notif in
							NavigationLink(destination: destinationView(for: notif)) {
								VStack(alignment: .leading) {
									ScrollView(.horizontal, showsIndicators: false) {
										HStack {
											if let subject = notif.subject {
												StateIconView(subject._type ?? .issue, subject.state ?? .open)
												if let url = URL(string: subject.htmlUrl ?? "") {
													Text("#\(url.lastPathComponent)")
														.font(.footnote)
														.foregroundStyle(.secondary)
												}
											}
											Text(notif.repository?.fullName ?? "")
										}
									}

									Text(notif.subject?.title?.emojized() ?? "")
								}
							}
							.buttonStyle(.plain)
							.swipeActions {
								HStack {
									if notif.unread == true || notif.pinned == true {
										Button("Mark read", systemImage: "envelope.open") {
											Task {
												guard let id = notif.id else { return }
												do {
													try await mark(id, status: .read)
													applyStatusChange(id: id, status: .read)
													HapticFeedback.notify(.success)
												} catch {
													HapticFeedback.notify(.error)
												}
											}
										}.tint(.accentColor)
									} else {
										Button("Mark pinned", systemImage: "pin") {
											Task {
												guard let id = notif.id else { return }
												do {
													try await mark(id, status: .pinned)
													applyStatusChange(id: id, status: .pinned)
													HapticFeedback.notify(.success)
												} catch {
													HapticFeedback.notify(.error)
												}
											}
										}.tint(.orange)
										Button("Mark unread", systemImage: "envelope.badge") {
											Task {
												guard let id = notif.id else { return }
												do {
													try await mark(id, status: .unread)
													applyStatusChange(id: id, status: .unread)
													HapticFeedback.notify(.success)
												} catch {
													HapticFeedback.notify(.error)
												}
											}
										}.tint(.accentColor)
									}
								}.labelStyle(.iconOnly)
							}
							.onAppear {
								if notif.id == data.last?.id, paging.hasMore {
									Task { await loadNextPage() }
								}
							}
						}
						if case .loadingMore = state {
							LoadingView("Loading more", systemImage: icon)
						} else if case .failedMore(_, let error) = state {
							FailedView(error)
						}
					}
				case .failed(let failure):
					FailedView(failure)
				}
			}
		}.task {
			await resetAndLoad()
		}.refreshable {
			await resetAndLoad()
		}.navigationTitle("Notifications")
	}

	@ViewBuilder
	private func destinationView(for notif: Components.Schemas.NotificationThread) -> some View {
		let owner = notif.repository?.owner?.login ?? ""
		let repo = notif.repository?.name ?? ""

		switch notif.subject?._type {
		case .issue:
			if let url = URL(string: notif.subject?.htmlUrl ?? ""), let index = Int64(url.lastPathComponent) {
				IssueLoader(owner: owner, repo: repo, index: index)
			} else if let repository = notif.repository {
				FullRepoView(repository)
			}
		case .pull:
			if let url = URL(string: notif.subject?.htmlUrl ?? ""), let index = Int64(url.lastPathComponent) {
				PullRequestLoader(owner: owner, repo: repo, index: index)
			} else if let repository = notif.repository {
				FullRepoView(repository)
			}
		case .commit:
			if let url = URL(string: notif.subject?.htmlUrl ?? "") {
				CommitsLoader(owner: owner, repo: repo, ref: url.lastPathComponent)
			} else if let repository = notif.repository {
				FullRepoView(repository)
			}
		case .repository:
			if let repository = notif.repository {
				FullRepoView(repository)
			}
		case .none:
			EmptyView()
		}
	}
}
