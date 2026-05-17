//
//  LoadableList.swift
//  Gitea
//
//  Created by Felix Schindler on 17.05.26.
//

import SwiftUI

struct LoadableList<Data, ID, Row>: View where Data: RandomAccessCollection, ID: Hashable, Row: View {
	let state: LoadState<Data>
	let id: KeyPath<Data.Element, ID>
	let loadingText: LocalizedStringResource
	let emptyText: LocalizedStringResource
	let icon: String
	let load: () async -> Void
	@ViewBuilder let row: (Data.Element) -> Row

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView(loadingText, systemImage: icon)
			case .loaded(let data):
				if data.isEmpty {
					NoContentView(emptyText, systemImage: icon)
				} else {
					ForEach(data, id: id) { element in
						row(element)
					}
				}
			case .failed(let failure):
				FailedView(failure)
			}
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
	}
}
