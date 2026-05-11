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
	@State var starredRepos: Result<[Components.Schemas.Repository], Error>?

	private func load() async {
		if let count = try? await Network.shared.client.notifyNewAvailable().ok.body.json.new, count > 0 {
			showNotificationsBadge = true
		}

		do {
			let repos = try await Network.shared.client.userCurrentListStarred().ok.body.json
			starredRepos = .success(repos)
		} catch {
			starredRepos = .failure(error)
		}
	}

	var body: some View {
		List {
			Section("Your work") {
				NavigationLink(destination: IssueSearchLoader(search: .constant(""))) {
					Label("Issues", systemImage: Icons.issues.rawValue)
				}
				Label("Pull Requests", systemImage: Icons.pull_requests.rawValue)
				Label("Milestones", systemImage: Icons.milestones.rawValue)
				NavigationLink(destination: UserReposLoader()) {
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
				if let starredRepos {
					switch starredRepos {
					case .success(let success):
						if success.isEmpty {
							NoContentView("You don't have starred repositories", systemImage: Icons.starred.rawValue)
						} else {
							ForEach(success, id: \.id) { repo in
								SmallRepoView(repo, showFullName: true)
							}
						}
					case .failure(let failure):
						FailedView(failure)
					}
				} else {
					LoadingView("Loading starred repositories", systemImage: Icons.starred.rawValue)
				}
			}
		}.toolbar {
			HStack {
				Menu("More", systemImage: "ellipsis") {
					NavigationLink(
						destination: NewRepoView(),
						label: {
							Label("New Repository", systemImage: "plus")
						})
					NavigationLink(
						destination: NewRepoMigrationView(),
						label: {
							Label("New Migration", systemImage: "square.grid.3x1.folder.badge.plus")
						})
					NavigationLink(
						destination: NewOrgaView(),
						label: {
							Label("New Organization", systemImage: Icons.organizations.rawValue)
						})
				}

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
