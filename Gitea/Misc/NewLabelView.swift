//
//  NewLabelView.swift
//  Gitea
//
//  Created by Felix Schindler on 22.05.26.
//

import SwiftUI

struct NewLabelView: View {
	@Environment(\.dismiss) private var dismiss

	let owner: String
	let repo: String

	@State private var name = ""
	@State private var color = Color(hex: "#FFFFFF")
	@State private var description = ""
	@State private var exclusive = false
	@State private var isArchived = false

	@State private var error: Error?

	private func create() async {
		do {
			_ = try await Network.shared.client.issueCreateLabel(
				path: .init(owner: owner, repo: repo),
				body: .json(
					.init(
						color: color.hex,
						description: description,
						exclusive: exclusive,
						isArchived: isArchived,
						name: name
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
				TextField("Name", text: $name)
				TextField("Description (optional)", text: $description, axis: .vertical)
					.lineLimit(3)
			}

			Section {
				ColorPicker("Color", selection: $color, supportsOpacity: false)
			}

			Section {
				Toggle("Exclusive", isOn: $exclusive)
				Toggle("Archived", isOn: $isArchived)
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(name.isEmpty)
				.buttonStyle(.borderedProminent)
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Label")
	}
}

#Preview {
	NavigationStack {
		NewLabelView(owner: "Tanuki", repo: "gitea-ios")
	}
}
