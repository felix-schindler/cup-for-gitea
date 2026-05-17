//
//  LoadableList.swift
//  Gitea
//
//  Created by Felix Schindler on 17.05.26.
//

import SwiftUI

struct LoadableList<Data, ID, Row>: View where Data: RandomAccessCollection, ID: Hashable, Row: View {
	let result: Result<Data, Error>?
	let id: KeyPath<Data.Element, ID>
	let loadingText: LocalizedStringResource
	let emptyText: LocalizedStringResource
	let icon: String
	let load: () async -> Void
	@ViewBuilder let row: (Data.Element) -> Row

	var body: some View {
		List {
			if let result {
				switch result {
				case .success(let data):
					if data.isEmpty {
						NoContentView(emptyText, systemImage: icon)
					} else {
						ForEach(data, id: id) { element in
							row(element)
						}
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView(loadingText, systemImage: icon)
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
