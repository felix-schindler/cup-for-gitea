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
	@State var notifications: Result<[Components.Schemas.NotificationThread], Error>?

	private func load() async {
		do {
			let notifications = try await Network.shared.client.notifyGetList(.init(query: .init(all: showAll))).ok.body.json
			self.notifications = .success(notifications)
		} catch {
			self.notifications = .failure(error)
		}
	}

	private func mark(_ id: Int64, status: StatusChange) async throws {
		_ = try await Network.shared.client.notifyReadThread(.init(path: .init(id: String(id)), query: .init(toStatus: status.rawValue))).resetContent.body.json
	}

	private func applyStatusChange(id: Int64, status: StatusChange) {
		guard case .success(let current) = notifications else { return }
		let shouldRemove: Bool
		switch status {
		case .read, .pinned:
			shouldRemove = showAll == false
		case .unread:
			shouldRemove = showAll == true
		}

		guard shouldRemove else { return }
		let updated = current.filter { $0.id != id }
		notifications = .success(updated)
	}

	var body: some View {
		List {
			Section {
				Picker("Show", selection: $showAll) {
					Text("Unread").tag(false)
					Text("Read").tag(true)
				}.onChange(of: showAll) {
					Task {
						await load()
					}
				}.pickerStyle(.segmented)
			}

			Section {
				if let notifications {
					switch notifications {
					case .success(let success):
						if success.isEmpty {
							NoContentView("All caught up!", systemImage: icon, description: "No unread notifications.")
						} else {
							ForEach(success, id: \.id) { notif in
								NavigationLink(destination: destinationView(for: notif)) {
									VStack(alignment: .leading) {
										ScrollView(.horizontal, showsIndicators: false) {
											HStack {
												StateIconView(notif.subject._type, notif.subject.state)
												Text(notif.repository.fullName)
												if let url = URL(string: notif.subject.htmlUrl) {
													Text("#\(url.lastPathComponent)")
														.font(.footnote)
														.foregroundStyle(.secondary)
												}
											}
										}

										InlineText(markdown: notif.subject.title.emojized(), baseURL: Network.shared.serverURL)
											.textual.inlineStyle(.gitHub)
											.textual.textSelection(.enabled)
									}
								}
								.buttonStyle(.plain)
								.swipeActions {
									HStack {
										if notif.unread || notif.pinned {
											Button("Mark read", systemImage: "envelope.open") {
												Task {
													do {
														try await mark(notif.id, status: .read)
														applyStatusChange(id: notif.id, status: .read)
														HapticFeedback.notify(.success)
													} catch {
														HapticFeedback.notify(.error)
													}
												}
											}.tint(.accentColor)
										} else {
											Button("Mark pinned", systemImage: "pin") {
												Task {
													do {
														try await mark(notif.id, status: .pinned)
														applyStatusChange(id: notif.id, status: .pinned)
														HapticFeedback.notify(.success)
													} catch {
														HapticFeedback.notify(.error)
													}
												}
											}.tint(.orange)
											Button("Mark unread", systemImage: "envelope.badge") {
												Task {
													do {
														try await mark(notif.id, status: .unread)
														applyStatusChange(id: notif.id, status: .unread)
														HapticFeedback.notify(.success)
													} catch {
														HapticFeedback.notify(.error)
													}
												}
											}.tint(.accentColor)
										}
									}.labelStyle(.iconOnly)
								}
							}
						}
					case .failure(let failure):
						FailedView(failure)
					}
				} else {
					LoadingView("Loading user notification thread", systemImage: icon)
				}
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Notifications")
	}

	@ViewBuilder
	private func destinationView(for notif: Components.Schemas.NotificationThread) -> some View {
		let owner = notif.repository.owner.login
		let repo = notif.repository.name

		switch notif.subject._type {
		case .issue:
			if let url = URL(string: notif.subject.htmlUrl), let index = Int64(url.lastPathComponent) {
				IssueLoader(owner: owner, repo: repo, index: index)
			} else {
				FullRepoView(notif.repository)
			}
		case .pull:
			if let url = URL(string: notif.subject.htmlUrl), let index = Int64(url.lastPathComponent) {
				PullRequestLoader(owner: owner, repo: repo, index: index)
			} else {
				FullRepoView(notif.repository)
			}
		case .commit:
			if let url = URL(string: notif.subject.htmlUrl) {
				CommitsLoader(owner: owner, repo: repo, ref: url.lastPathComponent)
			} else {
				FullRepoView(notif.repository)
			}
		case .repository:
			FullRepoView(notif.repository)
		}
	}
}
