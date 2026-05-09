//
//  ExploreView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI

struct ExploreView: View {
	var body: some View {
		List {
			NoContentView("Explore", systemImage: Icons.explore.rawValue)
		}.navigationTitle("Explore")
	}
}
