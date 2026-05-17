//
//  IssueSearchFiltersSheet.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct IssueSearchFiltersSheet: View {
	@Binding var filters: IssueSearchFilters
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		Form {
			Section("State") {
				Picker("State", selection: $filters.state) {
					ForEach(Operations.IssueSearchIssues.Input.Query.StatePayload.allCases, id: \.self) { option in
						Text(option.rawValue.capitalized).tag(option)
					}
				}
				.pickerStyle(.segmented)
			}

			Section("People") {
				Toggle("Assigned to me", isOn: $filters.assigned)
				Toggle("Created by me", isOn: $filters.created)
				Toggle("Mentioned me", isOn: $filters.mentioned)
				Toggle("Review requested", isOn: $filters.reviewRequested)
				Toggle("Reviewed", isOn: $filters.reviewed)
			}

			Section("Dates") {
				Toggle("Updated since", isOn: Binding(
					get: { filters.since != nil },
					set: { isOn in
						filters.since = isOn ? (filters.since ?? Date()) : nil
					}
				))
				if let since = filters.since {
					DatePicker("Since", selection: Binding(
						get: { since },
						set: { filters.since = $0 }
					), displayedComponents: [.date])
				}

				Toggle("Updated before", isOn: Binding(
					get: { filters.before != nil },
					set: { isOn in
						filters.before = isOn ? (filters.before ?? Date()) : nil
					}
				))
				if let before = filters.before {
					DatePicker("Before", selection: Binding(
						get: { before },
						set: { filters.before = $0 }
					), displayedComponents: [.date])
				}
			}

			Section("Labels & Milestones") {
				TextField("Labels (comma-separated)", text: $filters.labels)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Milestones (comma-separated)", text: $filters.milestones)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}

			Section("Scope") {
				TextField("Owner", text: $filters.owner)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Created by", text: $filters.createdBy)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Team", text: $filters.team)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}

			Section("Pagination") {
				TextField("Limit", text: $filters.limitText)
					.keyboardType(.numberPad)
			}
		}
		.navigationTitle("Filters")
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Reset") {
					filters = IssueSearchFilters()
				}
			}
			ToolbarItem(placement: .confirmationAction) {
				Button("Done", systemImage: "checkmark") {
					dismiss()
				}
			}
		}
	}
}
