//
//  HomeView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct HomeView: View {
	@State var showNotifications = false
	@State var showNotificationsBadge = false
	@State private var starredState = LoadState<[Components.Schemas.Repository]>.loading

	private func load() async {
		if let count = try? await Network.shared.client.notifyNewAvailable().ok.body.json.new, count > 0 {
			showNotificationsBadge = true
		}

		starredState = await LoadState {
			try await Network.shared.client.userCurrentListStarred().ok.body.json
		}
	}

	var body: some View {
		List {
			Section("Your work") {
				NavigationLink(destination: IssueSearchLoader(type: .issues)) {
					Label("Issues", systemImage: Icons.issues.rawValue)
				}
				NavigationLink(destination: IssueSearchLoader(type: .pulls)) {
					Label("Pull Requests", systemImage: Icons.pull_requests.rawValue)
				}
				NavigationLink(destination: RepoSearchLoader(context: .user(nil))) {
					Label("Repositories", systemImage: Icons.repositories.rawValue)
				}
				NavigationLink(destination: UserOrgLoader()) {
					Label("Organizations", systemImage: Icons.organizations.rawValue)
				}
				NavigationLink(destination: SubscriptionsLoader()) {
					Label("Subscriptions", systemImage: Icons.subscriptions.rawValue)
				}
			}

			Section("Starred repositories") {
				switch starredState {
				case .loading:
					LoadingView("Loading starred repositories", systemImage: Icons.starred.rawValue)
				case .loaded(let repos):
					if repos.isEmpty {
						NoContentView("You don't have starred repositories", systemImage: Icons.starred.rawValue)
					} else {
						ForEach(repos, id: \.id) { repo in
							SmallRepoView(repo, showFullName: true)
						}
					}
				case .failed(let failure):
					FailedView(failure)
				}
			}
		}.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Menu("Create", systemImage: "plus") {
					NavigationLink(destination: NewRepoView()) {
						Label("New Repository", systemImage: "plus")
					}
					NavigationLink(destination: NewRepoMigrationView()) {
						Label("New Migration", systemImage: "square.grid.3x1.folder.badge.plus")
					}
					NavigationLink(destination: NewOrgView()) {
						Label("New Organization", systemImage: Icons.organizations.rawValue)
					}
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				Button(
					action: {
						showNotifications = true
						HapticFeedback.play(.light)
					},
					label: {
						Image(systemName: showNotificationsBadge ? Icons.notificationsUnread.rawValue : Icons.notifications.rawValue)
							.symbolRenderingMode(.multicolor)
					})
			}
		}.sheet(isPresented: $showNotifications, onDismiss: { showNotifications = false }) {
			NavigationStack {
				NotificationLoader()
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Home")
	}
}

#Preview {
	NavigationStack {
		HomeView()
	}
}
