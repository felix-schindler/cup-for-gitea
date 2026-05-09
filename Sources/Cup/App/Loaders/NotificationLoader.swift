//
//  NotificationLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import GiteaAPI
import SwiftUI

struct NotificationLoader: View {
	private let icon = Icons.notifications.rawValue
	@State var notifications: Result<[Components.Schemas.NotificationThread], Error>?

	private func load() async {
		do {
			let notifications = try await Network.shared.client.notifyGetList().ok.body.json
			self.notifications = .success(notifications)
		} catch {
			self.notifications = .failure(error)
		}
	}

	var body: some View {
		List {
			if let notifications {
				switch notifications {
				case .success(let success):
					if success.isEmpty {
						NoContentView("All caught up!", systemImage: icon, description: "No unread notifications.")
					} else {
						ForEach(success, id: \.id!) { notification in
							VStack {
								if let url = notification.url {
									Text(url)
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
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Notifications")
	}
}
