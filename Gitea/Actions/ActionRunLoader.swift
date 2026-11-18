//
//  ActionRunLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

struct ActionRunLoader: View {
	let owner: String
	let repo: String
	let run: Int64

	@State private var state = LoadState<Components.Schemas.ActionWorkflowRun>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client.getWorkflowRun(
					path: .init(owner: owner, repo: repo, run: Int(run))
				).ok.body.json)
		} catch {
			state = .failed(error)
		}
	}

	var body: some View {
		Group {
			switch state {
			case .loading:
				LoadingView("Loading workflow run", systemImage: Icons.actions.rawValue)
			case .loaded(let run), .loadingMore(let run), .failedMore(let run, _):
				ActionView(run: run, owner: owner, repo: repo)
			case .failed(let failure):
				FailedView(failure)
			}
		}.task {
			await load()
		}
	}
}
