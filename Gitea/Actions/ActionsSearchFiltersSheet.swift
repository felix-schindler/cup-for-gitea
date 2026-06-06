//
//  ActionsSearchFiltersSheet.swift
//  Gitea
//
//  Created by Felix Schindler on 06.06.26.
//

import SwiftUI

struct ActionsSearchFiltersSheet: View {
	@Binding var filters: ActionsSearchFilters
	@Environment(\.dismiss) private var dismiss

	var body: some View {
		Form {
			Section("Status") {
				Picker("Status", selection: $filters.status) {
					ForEach(ActionsSearchFilters.StatusFilter.allCases, id: \.self) { option in
						Text(option.displayName).tag(option)
					}
				}
				.pickerStyle(.menu)
			}

			Section("Details") {
				TextField("Event", text: $filters.event)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Branch", text: $filters.branch)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				TextField("Actor", text: $filters.actor)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("Filters")
		.toolbar {
			ToolbarItem(placement: .cancellationAction) {
				Button("Reset") {
					filters = ActionsSearchFilters()
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
