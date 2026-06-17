//
//  GiteaApp.swift
//  Gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import CoreSpotlight
import SwiftUI

@main
struct GiteaApp: App {
	@StateObject private var sessionStore = SessionStore.shared
	@StateObject private var router = NavigationRouter()

	var body: some Scene {
		WindowGroup {
			Group {
				if sessionStore.needsSetup {
					SetupView()
				} else {
					ContentView()
				}
			}
			.environmentObject(router)
			.onContinueUserActivity("viewRepo") { activity in
				handleUserActivity(activity)
			}
			.onContinueUserActivity("viewIssue") { activity in
				handleUserActivity(activity)
			}
			.onContinueUserActivity("viewPullRequest") { activity in
				handleUserActivity(activity)
			}
			.onContinueUserActivity(CSSearchableItemActionType) { activity in
				guard let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
					let dest = SpotlightDestination.from(identifier: id)
				else { return }
				router.navigate(to: dest)
			}
		}
	}

	private func handleUserActivity(_ activity: NSUserActivity) {
		guard let info = activity.userInfo,
			let type = info["type"] as? String,
			let instanceURL = info["instanceURL"] as? String,
			let owner = info["owner"] as? String,
			let repo = info["repo"] as? String
		else { return }
		let dest: SpotlightDestination
		switch type {
		case "repo":
			dest = .repo(instanceURL: instanceURL, owner: owner, repo: repo)
		case "issue":
			guard let number = (info["number"] as? NSNumber)?.int64Value else { return }
			dest = .issue(instanceURL: instanceURL, owner: owner, repo: repo, number: number)
		case "pullRequest":
			guard let number = (info["number"] as? NSNumber)?.int64Value else { return }
			dest = .pullRequest(instanceURL: instanceURL, owner: owner, repo: repo, number: number)
		default:
			return
		}
		router.navigate(to: dest)
	}
}
