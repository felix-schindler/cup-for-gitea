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

    var body: some View {
        List {
            if results.isEmpty {
                if let error {
                    FailedView(error)
                } else if isLoading {
                    LoadingView(loadingText, systemImage: icon)
                } else {
                    NoContentView(emptyText, systemImage: icon)
                }
            } else {
                ForEach(results, id: \.id) { repo in
                    SmallRepoView(repo)
                        .onAppear {
                            if repo.id == results.last?.id, hasMorePages {
                                Task { await onLoadMore() }
                            }
                        }
                }
                if isLoading {
                    Section {
                        LoadingView(loadingMoreText, systemImage: icon)
                    }
                } else if let error {
                    Section {
                        FailedView(error)
                    }
                }
            }
        }
    }
}
