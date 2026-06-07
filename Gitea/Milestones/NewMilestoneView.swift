//
//  NewMilestoneView.swift
//  Gitea
//
//  Created by Felix Schindler on 22.05.26.
//

import SwiftUI

struct NewMilestoneView: View {
	@Environment(\.dismiss) private var dismiss

	let owner: String
	let repo: String

	@State private var title = ""
	@State private var description = ""
	@State private var setDueDate = false
	@State private var dueDate = Date()

	@State private var error: Error?

	private func create() async {
		do {
			_ = try await Network.shared.client.issueCreateMilestone(
				path: .init(owner: owner, repo: repo),
				body: .json(
					.init(
						description: description,
						dueOn: setDueDate ? dueDate : nil,
						state: .open,
						title: title
					))
			).created

			HapticFeedback.notify(.success)
			dismiss()
		} catch {
			self.error = error
			HapticFeedback.notify(.error)
		}
	}

	var body: some View {
		Form {
			if let error {
				Section {
					FailedView(error)
				}
			}

			Section {
				TextField("Title", text: $title)
				TextField("Description (optional)", text: $description, axis: .vertical)
					.lineLimit(5)
			}

			Section {
				Toggle("Set due date", isOn: $setDueDate)
				if setDueDate {
					DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
				}
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(title.isEmpty)
				.buttonStyle(.borderedProminent)
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Milestone")
	}
}

#Preview {
	NavigationStack {
		NewMilestoneView(owner: "Tanuki", repo: "gitea-ios")
	}
}
