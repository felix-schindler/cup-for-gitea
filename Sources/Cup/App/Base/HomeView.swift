//
//  HomeView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct HomeView: View {
	@State var showNotifications = false

	var body: some View {
		List {
			Section("Your work") {
				Text("Issues")
				Text("Pull Requests")
				Text("Milestones")
				NavigationLink("Repositories") {
					UserReposLoader()
				}
				Text("Organizations")
				Text("Starred")
				Text("Subscriptions")
				Text("Gitea settings")
			}
		}.toolbar {
			Button("Notifications", systemImage: "bell") {
				showNotifications = true
			}
		}.sheet(isPresented: $showNotifications, onDismiss: { showNotifications = false }) {
			Text("Notifications")
		}.navigationTitle("Home")
	}
}
