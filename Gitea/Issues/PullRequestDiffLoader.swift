import OpenAPIRuntime
import SwiftUI

struct PullRequestDiffLoader: View {
	let owner: String
	let repo: String
	let index: Int64

	@State private var state = LoadState<String>.loading

	private func load() async {
		state = await LoadState {
			let raw = try await Network.shared.client.repoDownloadPullDiffOrPatch(
				.init(
					path: .init(owner: owner, repo: repo, index: index, diffType: .diff),
					query: .init(binary: false)
				)
			).ok.body.plainText

			return try await String(collecting: raw, upTo: 2 * 1024 * 1024)
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading Diff", systemImage: "doc.text")
			case .loaded(let diffText), .loadingMore(let diffText), .failedMore(let diffText, _):
				DiffView(diffText: diffText)
			case .failed(let failure):
				FailedView(failure)
			}
		}
		.task {
			await load()
		}
		.navigationTitle("Files Changed")
		.navigationBarTitleDisplayMode(.inline)
	}
}
