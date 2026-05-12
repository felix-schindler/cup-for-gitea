//
//  SessionStore.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import Combine
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
	static let shared = SessionStore()

	@Published
	private(set) var needsSetup: Bool

	private init() {
		needsSetup = InstanceManager.selected == nil
	}

	func setNeedsSetup(_ value: Bool) {
		needsSetup = value
	}

	func refresh() {
		needsSetup = InstanceManager.selected == nil
	}
}
