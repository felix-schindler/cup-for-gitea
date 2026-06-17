import SwiftUI

struct RepoSearchResultsList: View {
	let results: [Components.Schemas.Repository]
	let error: Error?
	let icon: String
	let isLoading: Bool
	let hasMorePages: Bool
	let loadingText: LocalizedStringResource
	let loadingMoreText: LocalizedStringResource
	let emptyText: LocalizedStringResource
	let onLoadMore: () async -> Void

	private var state: LoadState<[Components.Schemas.Repository]> {
		if results.isEmpty {
			if let error {
				.failed(error)
			} else if isLoading {
				.loading
			} else {
				.loaded([])
			}
		} else {
			if isLoading {
				.loadingMore(results)
			} else if let error {
				.failedMore(results, error)
			} else {
				.loaded(results)
			}
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: loadingText,
			emptyText: emptyText,
			icon: icon,
			load: {},
			loadMore: onLoadMore,
			hasMorePages: hasMorePages,
			loadingMoreText: loadingMoreText
		) { repo in
			SmallRepoView(repo)
		}
	}
}
