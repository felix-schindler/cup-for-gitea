//
//  ActionsSearchFiltersSheet.swift
//  Gitea
//
//  Created by Felix Schindler on 06.06.26.
//

import SwiftUI

struct ActionsSearchFiltersSheet: View {
	@Binding var filters: ActionsSearchFilters

	var body: some View {
		FilterSheet(filters: $filters, initialValue: ActionsSearchFilters()) {
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
	}
}
