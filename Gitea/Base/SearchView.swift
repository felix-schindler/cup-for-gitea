//
//  SearchScreen.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum SearchType: String, CaseIterable {
	case repo = "Repo"
	case team = "Team"
	case user = "User"
	case topic = "Topic"
	case issue = "Issue"
}

struct SearchView: View {
	@State var type: SearchType = .repo
	@State var search: String = ""
	@State var results: Result<Void, Error>?

	// TODO: Search for the selected thing
	private func loadSearch() async throws {
		// try Network.shared.client.repoSearch()
		// try Network.shared.client.teamSearch()
		// try Network.shared.client.userSearch()
		// try Network.shared.client.topicSearch()
		// try Network.shared.client.issueSearchIssues()
	}

	var body: some View {
		VStack {
			Picker("Search for a", selection: $type) {
				ForEach(SearchType.allCases, id: \.self) { _type in
					Text(_type.rawValue).tag(_type)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal)

			List {
				if search.isEmpty {
					NoContentView("Start by entering a search term", systemImage: "magnifyingglass")
				} else {
					// TODO: List results
					Text(search)
				}
			}
		}
		.searchable(text: $search, prompt: Text("Search for a \(type.rawValue)"))
		.navigationTitle("Search")
	}
}
