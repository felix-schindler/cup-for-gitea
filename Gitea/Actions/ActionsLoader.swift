//
//  ActionsLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 27.05.26.
//

import SwiftUI

struct ActionsLoader: View {
	let owner: String
	let repo: String

	@State private var results: [Components.Schemas.ActionWorkflowRun] = []
	@State private var error: Error?
	@State private var isLoadingPage = false
	@State private var hasMorePages = true
	@State private var currentPage = 1

	private let defaultLimit = 20

	private func resetAndLoad() async {
		results = []
		error = nil
		currentPage = 1
		hasMorePages = true
		isLoadingPage = false
		await loadNextPage()
	}

	private func loadNextPage() async {
		guard !isLoadingPage, hasMorePages else { return }
		isLoadingPage = true
		defer { isLoadingPage = false }
		do {
			let response = try await Network.shared.client.getWorkflowRuns(
				path: .init(owner: owner, repo: repo),
				query: .init(page: currentPage, limit: defaultLimit)
			).ok.body.json
			if Task.isCancelled { return }
			results.append(contentsOf: response.workflowRuns)
			if response.workflowRuns.count < defaultLimit {
				hasMorePages = false
			} else {
				currentPage += 1
			}
		} catch {
			if Task.isCancelled { return }
			self.error = error
		}
	}

	var body: some View {
		List {
			if results.isEmpty {
				if let error {
					FailedView(error)
				} else if isLoadingPage {
					LoadingView("Loading Actions", systemImage: Icons.actions.rawValue)
				} else {
					NoContentView("There are no workflow runs", systemImage: Icons.actions.rawValue)
				}
			} else {
				ForEach(results, id: \.id) { run in
					NavigationLink(destination: ActionView(run: run, owner: owner, repo: repo)) {
						SmallActionView(run)
					}
					.onAppear {
						if run.id == results.last?.id, hasMorePages {
							Task { await loadNextPage() }
						}
					}
				}
				if isLoadingPage {
					Section {
						LoadingView("Loading more", systemImage: Icons.actions.rawValue)
					}
				} else if let error {
					Section {
						FailedView(error)
					}
				}
			}
		}
		.task {
			await resetAndLoad()
		}
		.refreshable {
			await resetAndLoad()
		}
		.navigationTitle("Actions")
	}
}
