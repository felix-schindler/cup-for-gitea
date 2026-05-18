//
//  IssueSearchFilters.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct IssueSearchFilters: Equatable {
	var state: Operations.IssueSearchIssues.Input.Query.StatePayload = .open
	var labels: String = ""
	var milestones: String = ""
	var owner: String = ""
	var createdBy: String = ""
	var team: String = ""
	var assigned: Bool = false
	var created: Bool = false
	var mentioned: Bool = false
	var reviewRequested: Bool = false
	var reviewed: Bool = false
	var since: Date?
	var before: Date?
	var limitText: String = ""

	var taskKey: String {
		[
			state.rawValue,
			labels,
			milestones,
			owner,
			createdBy,
			team,
			assigned.description,
			created.description,
			mentioned.description,
			reviewRequested.description,
			reviewed.description,
			since?.timeIntervalSince1970.description ?? "",
			before?.timeIntervalSince1970.description ?? "",
			limitText,
		].joined(separator: "|")
	}

	var labelsValue: String? { trimmedOrNil(labels) }
	var milestonesValue: String? { trimmedOrNil(milestones) }
	var ownerValue: String? { trimmedOrNil(owner) }
	var createdByValue: String? { trimmedOrNil(createdBy) }
	var teamValue: String? { trimmedOrNil(team) }
	var limitValue: Int? { intOrNil(limitText, minimum: 1) }

	private func trimmedOrNil(_ value: String) -> String? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		return trimmed.isEmpty ? nil : trimmed
	}

	private func intOrNil(_ value: String, minimum: Int) -> Int? {
		let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
		guard let intValue = Int(trimmed), intValue >= minimum else { return nil }
		return intValue
	}
}
