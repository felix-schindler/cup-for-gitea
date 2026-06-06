//
//  ActionsSearchFilters.swift
//  Gitea
//
//  Created by Felix Schindler on 06.06.26.
//

import SwiftUI

struct ActionsSearchFilters: Equatable {
	var status: StatusFilter = .all
	var event: String = ""
	var branch: String = ""
	var actor: String = ""

	enum StatusFilter: String, CaseIterable, Equatable {
		case all
		case success
		case failure
		case cancelled
		case inProgress = "in_progress"
		case queued
		case pending
		case skipped

		var displayName: LocalizedStringResource {
			switch self {
			case .all: "All"
			case .success: "Success"
			case .failure: "Failure"
			case .cancelled: "Cancelled"
			case .inProgress: "In Progress"
			case .queued: "Queued"
			case .pending: "Pending"
			case .skipped: "Skipped"
			}
		}
	}

	var taskKey: String {
		[status.rawValue, event, branch, actor].joined(separator: "|")
	}

	var eventFilter: String? { trimmedOrNil(event) }
	var branchFilter: String? { trimmedOrNil(branch) }
	var actorFilter: String? { trimmedOrNil(actor) }

	private func trimmedOrNil(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}
}
