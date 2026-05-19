//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct TopicsSearchLoader: View {
	@Binding var search: String
	@State private var state = LoadState<[Components.Schemas.TopicResponse]>.loading
	private let icon = Icons.topics.rawValue
	private let debounceNanoseconds: UInt64 = 350_000_000

	private func load(debounced: Bool = false) async {
		state = .loading
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		state = await LoadState {
			try await Network.shared.client.topicSearch(.init(query: .init(q: search))).ok.body.json.topics
		}
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView("Loading Topics", systemImage: icon)
			case .loaded(let topics):
				if topics.isEmpty {
					NoContentView("There are no Topics", systemImage: icon)
				} else {
					ForEach(topics, id: \.id) { topic in
						NavigationLink(destination: RepoSearchLoader(context: .search, search: topic.topicName, limitToTopic: true)) {
							HStack {
								Text(topic.topicName)
								Spacer()
								Text("\(topic.repoCount)")
							}
						}
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}.task(id: search) {
			await load(debounced: true)
		}.refreshable {
			await load()
		}.navigationTitle("Topics")
	}
}
