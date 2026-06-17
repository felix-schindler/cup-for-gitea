import SwiftUI

struct RepoLoader: View {
	let owner: String
	let repo: String

	@State private var state = LoadState<Components.Schemas.Repository>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.repoGet(.init(path: .init(owner: owner, repo: repo)))
				.ok.body.json
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading Repository", systemImage: Icons.repositories.rawValue)
			case .loaded(let repo), .loadingMore(let repo), .failedMore(let repo, _):
				FullRepoView(repo)
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}.navigationTitle("Repository")
			.navigationBarTitleDisplayMode(.inline)
	}
}
