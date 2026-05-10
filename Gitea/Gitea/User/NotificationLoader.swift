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

	// TODO: FIXME: This doesn't work
	private func mark(_ id: Int64, status: StatusChange) async throws {
		_ = try await Network.shared.client.notifyReadThread(.init(path: .init(id: String(id)), query: .init(toStatus: status.rawValue))).resetContent.body.json
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
								VStack(alignment: .leading) {
									ScrollView(.horizontal) {
										HStack {
											StateIconView(notif.subject._type, notif.subject.state)
											Text(notif.repository.fullName)
											if let url = URL(string: notif.subject.htmlUrl) {
												Link("#\(url.lastPathComponent)", destination: url)
													.tint(.accentColor)
													.buttonStyle(.bordered)
													.controlSize(.mini)
													.font(.footnote)
											}
										}
									}
									
									InlineText(markdown: notif.subject.title.emojized(), baseURL: Network.shared.serverURL)
										.textual.structuredTextStyle(.gitHub)
										.textual.textSelection(.enabled)
								}.swipeActions {
									// TODO: Haptic feedback; Update without re-fetching
									if notif.unread || notif.pinned {
										Button("Mark read", systemImage: "envelope.open") {
											Task {
												try? await mark(notif.id, status: .read)
											}
										}.tint(.accentColor)
									} else {
										Button("Mark pinned", systemImage: "pin") {
											Task {
												try? await mark(notif.id, status: .pinned)
											}
										}.tint(.orange)
										Button("Mark unread", systemImage: "envelope.badge") {
											Task {
												try? await mark(notif.id, status: .unread)
											}
										}.tint(.accentColor)
									}
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
}
