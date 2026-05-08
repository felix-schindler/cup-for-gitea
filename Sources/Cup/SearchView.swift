//
//  SearchScreen.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import SwiftUI

enum SearchType {
	case repo, team, user, topic, issue
}

// Cool new iOS 26 search screen in bottom tab bar (TODO: change in ContentView)
struct SearchView: View {
	@State var search: String = ""
	@State var results: Result<Void, Error>?
	
	// TODO: Search for the selected thing
	private func loadSearch() async throws -> Void {
		// try Network.shared.client.repoSearch()
		// try Network.shared.client.teamSearch()
		// try Network.shared.client.userSearch()
		// try Network.shared.client.topicSearch()
		// try Network.shared.client.issueSearchIssues()
	}
	
	var body: some View {
		// TODO: Let the user choose search type and enter search string
		// TODO: List results
	}
}
