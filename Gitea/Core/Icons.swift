//
//  Icons.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

enum Icons: String {
	// MARK: - ContentView
	case home = "house"
	case users = "person"
	case settings = "gear"
	case search = "magnifyingglass"
	// MARK: - HomeView
	case notifications = "tray"
	case notificationsUnread = "tray.badge"
	case repositories = "book.closed.fill"
	case issues = "dot.circle"
	case pull_requests = "arrow.triangle.pull"
	case pull_request_closed = "arrow.triangle.swap"
	case pull_request_merged = "arrow.triangle.merge"
	case milestones = "signpost.right"
	case organizations = "building.2"
	case starred = "star"
	case subscriptions = "bell"
	case topics = "tag"
	case share = "square.and.arrow.up"
	// MARK: - Repositories
	case forks = "tuningfork"
	case watchers = "eye"
	case code = "chevron.left.forwardslash.chevron.right"
	case commits = "clock.arrow.trianglehead.counterclockwise.rotate.90"
	case projects = "uiwindow.split.2x1"
	case packages = "cube"
	case activity = "radiowaves.right"
	case comments = "note.text"
	// MARK: - Actions
	case actions = "play.rectangle"
	case actionsSuccess = "checkmark.circle.fill"
	case actionsFailure = "xmark.circle.fill"
	case actionsCancelled = "xmark.circle"
	case actionsPending = "circle.dotted"
	case actionsInProgress = "ellipsis.circle"
}
