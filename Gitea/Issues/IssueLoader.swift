import SwiftUI

struct IssueLoader: View {
    let owner: String
    let repo: String
    let index: Int64

    @State private var state = LoadState<Components.Schemas.Issue>.loading

    private func load() async {
        state = await LoadState {
            try await Network.shared.client
                .issueGetIssue(path: .init(owner: owner, repo: repo, index: index))
                .ok.body.json
        }
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                LoadingView("Loading Issue", systemImage: Icons.issues.rawValue)
            case .loaded(let issue):
                IssueView(issue)
            case .failed(let failure):
                FailedView(failure)
            }
        }.task {
            await load()
        }.navigationTitle("Issue")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IssueLoader(owner: "gitea", repo: "gitea", index: 1)
    }
}
