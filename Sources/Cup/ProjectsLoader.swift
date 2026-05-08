//
//  ProjectsLoader.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import GiteaAPI
import SwiftUI

struct ProjectsLoader: View {
	@State var projects: Result<Void, Error>?
	
	private func loadProjects() async -> Void {
	}
	
	var body: some View {
		List {
			if let projects {
				// Show each project name
			} else {
				ProgressView("Loading Projects")
			}
		}.onAppear {
			Task {
				await loadProjects()
			}
		}
	}
}
