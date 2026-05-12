//
//  GiteaApp.swift
//  Gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

@main
struct GiteaApp: App {
	@StateObject private var sessionStore = SessionStore.shared

	var body: some Scene {
		WindowGroup {
			if sessionStore.needsSetup {
				SetupView()
			} else {
				ContentView()
			}
		}
	}
}
