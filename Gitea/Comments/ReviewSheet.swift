//
//  ReviewSheet.swift
//  Gitea
//
//  Created by Felix Schindler on 12.06.26.
//

import SwiftUI

struct ReviewSheet: View {
	let owner: String
	let repo: String
	let index: Int64
	let commitId: String
	let onComplete: () -> Void

	@Environment(\.dismiss) private var dismiss

	@State private var bodyText = ""
	@State private var event: Components.Schemas.CreatePullReviewOptions.EventPayload
	@State private var isSubmitting = false

	init(
		owner: String,
		repo: String,
		index: Int64,
		initialEvent: Components.Schemas.CreatePullReviewOptions.EventPayload = .comment,
		commitId: String,
		onComplete: @escaping () -> Void
	) {
		self.owner = owner
		self.repo = repo
		self.index = index
		self.commitId = commitId
		self.onComplete = onComplete
		self._event = State(initialValue: initialEvent)
	}
	@State private var error: Error?
	@State private var showError = false

	private var sheetTitle: String {
		switch event {
		case .approved: "Approve"
		case .comment: "Comment"
		case .requestChanges: "Request Changes"
		case .pending: "Pending Review"
		case .requestReview: "Request Review"
		}
	}

	var body: some View {
		NavigationStack {
			Form {
				Section("Type") {
					Picker("Review", selection: $event) {
						Text("Comment").tag(Components.Schemas.CreatePullReviewOptions.EventPayload.comment)
						Text("Approve").tag(Components.Schemas.CreatePullReviewOptions.EventPayload.approved)
						Text("Request Changes").tag(Components.Schemas.CreatePullReviewOptions.EventPayload.requestChanges)
					}
					.pickerStyle(.menu)
				}

				Section("Comment") {
					ZStack(alignment: .topLeading) {
						if bodyText.isEmpty {
							Text("Leave a comment")
								.foregroundStyle(.secondary)
								.padding(.top, 8)
								.padding(.leading, 4)
						}
						TextEditor(text: $bodyText)
							.frame(minHeight: 120)
					}
				}

				Section {
					AsyncButton("Submit Review") {
						await submit()
					}
					.disabled(isSubmitting || (event == .requestChanges && bodyText.isEmpty))
					.frame(maxWidth: .infinity)
				}
			}
			.navigationTitle(sheetTitle)
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
			}
		}
		.alert("Error", isPresented: $showError, presenting: error) { _ in
			Button("OK") {}
		} message: { error in
			Text(error.localizedDescription)
		}
	}

	private func submit() async {
		isSubmitting = true
		defer { isSubmitting = false }
		do {
			let response = try await Network.shared.client.repoCreatePullReview(
				.init(
					path: .init(owner: owner, repo: repo, index: index),
					body: .json(
						.init(
							body: bodyText,
							comments: [],
							commitId: commitId,
							event: event
						))
				)
			)
			switch response {
			case .ok:
				HapticFeedback.notify(.success)
				onComplete()
				dismiss()
			case .unprocessableContent(let error):
				self.error = NSError(
					domain: "", code: 422,
					userInfo: [NSLocalizedDescriptionKey: error.headers.message ?? "Validation error"]
				)
				showError = true
				HapticFeedback.notify(.error)
			case .notFound:
				self.error = NSError(
					domain: "", code: 404,
					userInfo: [NSLocalizedDescriptionKey: "Review not found"]
				)
				showError = true
				HapticFeedback.notify(.error)
			case .undocumented:
				self.error = NSError(
					domain: "", code: 0,
					userInfo: [NSLocalizedDescriptionKey: "An unexpected error occurred"]
				)
				showError = true
				HapticFeedback.notify(.error)
			}
		} catch {
			self.error = error
			showError = true
			HapticFeedback.notify(.error)
		}
	}
}
