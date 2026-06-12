//
//  ReviewsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 12.06.26.
//

import SwiftUI
import Textual

struct ReviewsLoader: View {
	let owner: String
	let repo: String
	let index: Int64
	var refreshID: Int = 0

	@State private var state = LoadState<[Components.Schemas.PullReview]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.repoListPullReviews(.init(path: .init(owner: owner, repo: repo, index: index)))
				.ok.body.json
		}
	}

	var body: some View {
		Section("Reviews") {
			switch state {
			case .loading:
				LoadingView("Loading reviews", systemImage: "checkmark.circle")
			case .loaded(let reviews):
				if reviews.isEmpty {
					NoContentView("No reviews yet", systemImage: "checkmark.circle")
				} else {
					ForEach(reviews, id: \.id) { review in
						ReviewRow(
							review: review,
							owner: owner,
							repo: repo,
							index: index,
							onReviewChanged: { Task { await load() } }
						)
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}
		.task(id: refreshID) {
			await load()
		}
		.refreshable {
			await load()
		}
	}
}

private struct ReviewRow: View {
	let review: Components.Schemas.PullReview
	let owner: String
	let repo: String
	let index: Int64
	let onReviewChanged: () -> Void

	var body: some View {
		VStack(alignment: .leading) {
			HStack {
				ScrollView(.horizontal) {
					SmallUserView(review.user)
				}
				Spacer()
				VStack(alignment: .trailing) {
					Text(review.submittedAt.toString(timeStyle: .short))
					if review.dismissed {
						Text("Dismissed")
					} else if review.stale {
						Text("Stale")
					} else {
						ReviewStateIcon(state: review.state)
					}
				}
				.font(.footnote)
				.foregroundStyle(.secondary)
			}

			if review.body.isNotEmpty {
				StructuredText(markdown: review.body.emojized())
					.textual.structuredTextStyle(.gitHub)
					.textual.textSelection(.enabled)
			}
		}
	}
}
