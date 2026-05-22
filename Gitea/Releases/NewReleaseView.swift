//
//  NewReleaseView.swift
//  Gitea
//
//  Created by Felix Schindler on 22.05.26.
//

import SwiftUI

struct NewReleaseView: View {
	@Environment(\.dismiss) private var dismiss

	let owner: String
	let repo: String

	@State private var tagName = ""
	@State private var tagMessage = ""
	@State private var name = ""
	@State private var targetCommitish = ""
	@State private var bodyText = ""
	@State private var draft = false
	@State private var prerelease = false

	@State private var error: Error?

	private func create() async {
		do {
			_ = try await Network.shared.client.repoCreateRelease(
				path: .init(owner: owner, repo: repo),
				body: .json(
					.init(
						body: bodyText,
						draft: draft,
						name: name.isEmpty ? tagName : name,
						prerelease: prerelease,
						tagMessage: tagMessage,
						tagName: tagName,
						targetCommitish: targetCommitish
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
				VStack(alignment: .leading) {
					TextField("Tag Name", text: $tagName)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Text("The git tag to associate with this release, e.g. v1.0.0.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				VStack(alignment: .leading) {
					TextField("Release Title (optional)", text: $name)
					Text("Defaults to the tag name if empty.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				TextField("Target (optional)", text: $targetCommitish)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			} header: {
				Text("Tag")
			}

			Section {
				TextField("Tag Message (optional)", text: $tagMessage, axis: .vertical)
					.lineLimit(5)
			} header: {
				Text("Annotation")
			}

			Section {
				TextField("Release Notes (optional)", text: $bodyText, axis: .vertical)
					.lineLimit(10)
			}

			Section {
				Toggle("Draft", isOn: $draft)
				Toggle("Pre-release", isOn: $prerelease)
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(tagName.isEmpty)
				.buttonStyle(.borderedProminent)
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Release")
	}
}

#Preview {
	NavigationStack {
		NewReleaseView(owner: "Tanuki", repo: "gitea-ios")
	}
}
