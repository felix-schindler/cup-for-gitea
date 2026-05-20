import SwiftUI

struct ActivityLoader: View {
    enum Context {
        case home
        case user(String)
        case org(String)
    }

    let context: Context

    @State private var state = LoadState<[Components.Schemas.Activity]>.loading
    @State private var heatmap: [Components.Schemas.UserHeatmapData]?
    @State private var heatmapError: Error?

    private var showHeatmap: Bool {
        if case .org = context { return false }
        return true
    }

    private var showActor: Bool {
        if case .user = context { return false }
        return true
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                LoadingView("Loading activity", systemImage: Icons.activity.rawValue)
            case .loaded(let activities):
                List {
                    if showHeatmap, let heatmap, heatmap.isNotEmpty {
                        Section {
                            ContributionGraphView(data: heatmap)
                                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                    }

                    if activities.isEmpty {
                        Section {
                            NoContentView("No recent activity", systemImage: Icons.activity.rawValue)
                        }
                    } else {
                        Section {
                            ForEach(activities, id: \.id) { activity in
                                ActivityView(activity: activity, showActor: showActor)
                            }
                        }
                    }
                }
            case .failed(let failure):
                FailedView(failure)
            }
        }
        .task {
            await load()
        }
        .refreshable {
            await load()
        }
        .navigationTitle("Activity")
    }

    private func load() async {
        switch context {
        case .home:
            do {
                let user = try await Network.shared.client.userGetCurrent().ok.body.json
                let activities = try await Network.shared.client.userListActivityFeeds(.init(path: .init(username: user.login))).ok.body.json
                state = .loaded(activities)
                await loadHeatmap(username: user.login)
            } catch {
                state = .failed(error)
            }
        case .user(let username):
            do {
                let activities = try await Network.shared.client.userListActivityFeeds(.init(path: .init(username: username))).ok.body.json
                state = .loaded(activities)
                await loadHeatmap(username: username)
            } catch {
                state = .failed(error)
            }
        case .org(let org):
            do {
                let activities = try await Network.shared.client.orgListActivityFeeds(.init(path: .init(org: org))).ok.body.json
                state = .loaded(activities)
            } catch {
                state = .failed(error)
            }
        }
    }

    private func loadHeatmap(username: String) async {
        do {
            heatmap = try await Network.shared.client.userGetHeatmapData(.init(path: .init(username: username))).ok.body.json
        } catch {
            heatmapError = error
        }
    }
}
