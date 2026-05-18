//
//  Auth.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI

@MainActor
class Auth {
	public static func login(
		instance: GiteaInstance,
		showSetup: Binding<Bool>? = nil,
		dismiss: DismissAction? = nil
	) async throws {
		guard instance.token.isNotEmpty else {
			throw AuthError.missingToken
		}
		let previousInstance = InstanceManager.selected
		InstanceManager.add(instance)
		resetSessionCaches()

		do {
			_ = try await Network.shared.client.userGetCurrent().ok.body.json
			showSetup?.wrappedValue = false
			dismiss?()
			SessionStore.shared.refresh()
		} catch {
			InstanceManager.remove(instance)
			if let previousInstance {
				InstanceManager.select(previousInstance)
				resetSessionCaches()
			}
			SessionStore.shared.refresh()
			throw error
		}
	}

	@MainActor
	public static func logout(showSetup: Binding<Bool>? = nil) {
		if let current = InstanceManager.selected {
			InstanceManager.remove(current)
		}

		resetSessionCaches()
		if InstanceManager.selected == nil {
			showSetup?.wrappedValue = true
		}
		SessionStore.shared.refresh()
	}

	@MainActor
	public static func switchInstance(to instance: GiteaInstance) async throws {
		guard instance.token.isNotEmpty else {
			throw AuthError.missingToken
		}
		InstanceManager.select(instance)
		resetSessionCaches()
		_ = try await Network.shared.client.userGetCurrent().ok.body.json
		SessionStore.shared.refresh()
	}

	private static func resetSessionCaches() {
		URLCache.shared.removeAllCachedResponses()
		URLCache.avatarCache.removeAllCachedResponses()
	}
}

enum AuthError: LocalizedError {
	case missingToken

	var errorDescription: String? {
		switch self {
		case .missingToken:
			String(localized: "Missing access token")
		}
	}
}
