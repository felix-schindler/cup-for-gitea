//
//  SearchScreen.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum SearchType: String, CaseIterable {
	case user = "User"
	case topic = "Topic"

	var displayName: LocalizedStringResource {
		switch self {
		case .user: "User"
		case .topic: "Topic"
		}
	}
}

struct SearchView: View {
	@State var type: SearchType = .user

	var body: some View {
		VStack(spacing: 0) {
			Picker("Search for a", selection: $type) {
				ForEach(SearchType.allCases, id: \.self) { _type in
					Text(_type.displayName).tag(_type)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal)

			switch type {
			case .user:
				UserSearchLoader(context: .search)
			case .topic:
				TopicSearchView()
			}
		}
		.navigationTitle("Search")
	}
}

private struct TopicSearchView: View {
	@State private var search = ""

	var body: some View {
		TopicsSearchLoader(search: $search)
			.searchable(text: $search, prompt: Text("Search for a topic"))
	}
}
