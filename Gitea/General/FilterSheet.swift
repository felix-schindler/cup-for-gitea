//
//  FilterSheet.swift
//  Gitea
//
//  Created by Felix Schindler on 09.07.26.
//

import SwiftUI

struct FilterSheet<T: Equatable, Content: View>: View {
	@Binding var filters: T
	let initialValue: T
	@Environment(\.dismiss) private var dismiss
	@ViewBuilder let content: () -> Content

	var body: some View {
		NavigationStack {
			Form {
				content()
			}
			.scrollDismissesKeyboard(.immediately)
			.navigationTitle("Filters")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Reset") { filters = initialValue }
				}
				ToolbarItem(placement: .confirmationAction) {
					Button("Done", systemImage: "checkmark") { dismiss() }
				}
			}
		}
	}
}
