//
//  SearchScreen.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum SearchType: String, CaseIterable {
	case repo = "Repo"
	case user = "User"
	case topic = "Topic"
	case issue = "Issue"
}

struct SearchView: View {
	@State var type: SearchType = .repo
	@State var search: String = ""

	var body: some View {
		VStack {
			Picker("Search for a", selection: $type) {
				ForEach(SearchType.allCases, id: \.self) { _type in
					Text(_type.rawValue).tag(_type)
				}
			}
			.pickerStyle(.segmented)
			.padding(.horizontal)

			switch type {
			case .repo:
				RepoSearchLoader(search: $search)
			case .user:
				UserSearchLoader(search: $search)
			case .topic:
				TopicsSearchLoader(search: $search)
			case .issue:
				IssueSearchLoader(search: $search)
			}
		}
		.searchable(text: $search, prompt: Text("Search for a \(type.rawValue)"))
		.navigationTitle("Search")
	}
}
