//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

struct TopicsSearchLoader: View {
	@Binding var search: String
	@State private var results: Result<[Components.Schemas.TopicResponse], Error>?
	private let icon = Icons.topics.rawValue

	private func load() async {
		do {
			let results = try await Network.shared.client.topicSearch(.init(query: .init(q: search))).ok.body.json
			self.results = .success(results)
		} catch {
			self.results = .failure(error)
		}
	}

	var body: some View {
		List {
			if let results {
				switch results {
				case .success(let success):
					if success.isEmpty {
						NoContentView("There are no Topics", systemImage: icon)
					} else {
						ForEach(success, id: \.id) { topic in
							HStack {
								Text(topic.topicName)
								Spacer()
								Text("\(topic.repoCount)")
							}
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading Topics", systemImage: icon)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.navigationTitle("Topics")
	}
}
