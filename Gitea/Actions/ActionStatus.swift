//
//  ActionStatus.swift
//  Gitea
//
//  Created by Felix Schindler on 06.06.26.
//

import SwiftUI

enum ActionStatus {
	case success
	case failure
	case cancelled
	case inProgress
	case pending
	case queued
	case unknown

	init(conclusion: String?, status: String) {
		if conclusion == "success" {
			self = .success
		} else if conclusion == "failure" {
			self = .failure
		} else if conclusion == "cancelled" || conclusion == "skipped" {
			self = .cancelled
		} else if status == "in_progress" {
			self = .inProgress
		} else if status == "queued" || status == "pending" {
			self = .pending
		} else {
			self = .unknown
		}
	}

	var icon: String {
		switch self {
		case .success:
			return Icons.actionsSuccess.rawValue
		case .failure:
			return Icons.actionsFailure.rawValue
		case .cancelled:
			return Icons.actionsCancelled.rawValue
		case .inProgress:
			return Icons.actionsInProgress.rawValue
		case .pending, .queued:
			return Icons.actionsPending.rawValue
		case .unknown:
			return Icons.actions.rawValue
		}
	}

	var color: Color {
		switch self {
		case .success:
			.green
		case .failure:
			.red
		case .cancelled:
			.gray
		case .inProgress:
			.orange
		case .pending, .queued:
			.yellow
		case .unknown:
			.primary
		}
	}

	var label: LocalizedStringKey {
		switch self {
		case .success:
			"Success"
		case .failure:
			"Failure"
		case .cancelled:
			"Cancelled"
		case .inProgress:
			"In Progress"
		case .pending:
			"Pending"
		case .queued:
			"Queued"
		case .unknown:
			"Unknown"
		}
	}
}
