//
//  HomeView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI
import UIKit

struct HomeView: View {
	@State var showNotifications = false
	@State var showNotificationsBadge = false
	@State private var versionWarning: String?
	@State private var starredState = LoadState<[Components.Schemas.Repository]>.loading
	@State private var jumpTarget: JumpTarget?
	@State private var jumpDiagnostics: JumpDiagnostics?

	private func jumpToClipboard() {
		let pasted = UIPasteboard.general.string ?? UIPasteboard.general.url?.absoluteString
		let host = InstanceManager.selected?.displayURL ?? Network.baseURL.absoluteString
		var diagnostics = JumpDiagnostics(raw: pasted ?? "", host: host)

		if let pasted, pasted.isNotEmpty {
			do {
				diagnostics.target = try JumpURL.parse(pasted, host: host)
			} catch let error as JumpURLError {
				diagnostics.error = error
			} catch {
				diagnostics.error = .notALink(raw: pasted)
			}
		} else {
			diagnostics.error = .emptyClipboard
		}

		guard let target = diagnostics.target else {
			HapticFeedback.notify(.warning)
			jumpDiagnostics = diagnostics
			return
		}

		jumpTarget = target
	}

	private func load() async {
		if let version = try? await Network.shared.client.getVersion().ok.body.json.version {
			let instanceURL = InstanceManager.selected?.displayURL ?? ""
			if InstanceManager.compareVersions(version, InstanceManager.minimumRequiredVersion) == .orderedAscending,
				InstanceManager.shouldShowVersionWarning(for: instanceURL, serverVersion: version)
			{
				versionWarning = version
			} else {
				versionWarning = nil
			}
		}

		if let count = try? await Network.shared.client.notifyNewAvailable().ok.body.json.new, count > 0 {
			showNotificationsBadge = true
		}

		do {
			starredState = .loaded(
				try await Network.shared.client.userCurrentListStarred(
					.init(query: .init(page: 1, limit: 7))
				).ok.body.json)
		} catch {
			starredState = .failed(error)
		}
	}

	var body: some View {
		List {
			if let versionWarning {
				Section {
					Label(
						"This instance runs Gitea \(versionWarning). Cup requires v\(InstanceManager.minimumRequiredVersion) or later — some features may not work.",
						systemImage: "exclamationmark.triangle.fill"
					)
					.swipeActions {
						Button("Acknowledge", systemImage: "xmark") {
							let instanceURL = InstanceManager.selected?.displayURL ?? ""
							InstanceManager.acknowledgeVersionWarning(for: instanceURL, serverVersion: versionWarning)
							self.versionWarning = nil
						}
					}
				}
			}

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
				case .loaded(let repos), .loadingMore(let repos), .failedMore(let repos, _):
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
				Button("Jump", systemImage: "arrow.right.page.on.clipboard") {
					jumpToClipboard()
				}
			}
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
		}.navigationDestination(item: $jumpTarget) { target in
			jumpDestination(target)
		}.alert(
			jumpDiagnostics?.summary ?? "",
			isPresented: Binding(
				get: { jumpDiagnostics != nil },
				set: { if !$0 { jumpDiagnostics = nil } }
			)
		) {
			Button("OK", role: .cancel) {}
		} message: {
			if let message = jumpDiagnostics?.message {
				Text(message)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Home")
	}

	@ViewBuilder
	private func jumpDestination(_ target: JumpTarget) -> some View {
		switch target {
		case .namespace(let username):
			NamespaceLoader(username)
		case .repository(let owner, let repo):
			RepoLoader(owner: owner, repo: repo)
		case .issue(let owner, let repo, let index):
			IssueLoader(owner: owner, repo: repo, index: index)
		case .pullRequest(let owner, let repo, let index):
			PullRequestLoader(owner: owner, repo: repo, index: index)
		case .route(let owner, let repo, let route):
			jumpRoute(owner: owner, repo: repo, route: route)
		}
	}

	@ViewBuilder
	private func jumpRoute(owner: String, repo: String, route: JumpRoute) -> some View {
		switch route {
		case .issues:
			IssueSearchLoader(type: .issues, owner: owner, repo: repo)
		case .pulls:
			IssueSearchLoader(type: .pulls, owner: owner, repo: repo)
		case .releases(let tag):
			if let tag {
				ReleaseTagLoader(owner: owner, repo: repo, tag: tag)
			} else {
				ReleaseLoader(owner: owner, repo: repo)
			}
		case .actions:
			ActionsLoader(owner: owner, repo: repo)
		case .run(let id):
			ActionRunLoader(owner: owner, repo: repo, run: id)
		case .commits(let ref):
			CommitsLoader(owner: owner, repo: repo, ref: ref)
		case .commit(let sha):
			CommitLoader(owner: owner, repo: repo, sha: sha)
		case .tree(let ref, let path):
			if let path {
				RepoPathLoader(owner: owner, repo: repo, ref: ref, path: path)
			} else {
				TreeLoader(owner: owner, repo: repo, ref: ref)
			}
		}
	}
}

#Preview {
	NavigationStack {
		HomeView()
	}
}
