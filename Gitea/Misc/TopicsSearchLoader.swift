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
	private let debounceNanoseconds: UInt64 = 350_000_000

	private func load(debounced: Bool = false) async {
		self.results = nil
		if debounced {
			try? await Task.sleep(nanoseconds: debounceNanoseconds)
			if Task.isCancelled { return }
		}
		do {
			let results = try await Network.shared.client.topicSearch(.init(query: .init(q: search))).ok.body.json
			if Task.isCancelled { return }
			self.results = .success(results.topics)
		} catch {
			if Task.isCancelled { return }
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
		}.task(id: search) {
			await load(debounced: true)
		}.refreshable {
			await load()
		}.navigationTitle("Topics")
	}
}
