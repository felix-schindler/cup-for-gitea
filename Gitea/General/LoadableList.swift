import SwiftUI

struct LoadableList<Data, ID, Row>: View where Data: RandomAccessCollection, ID: Hashable, Row: View {
	let state: LoadState<Data>
	let id: KeyPath<Data.Element, ID>
	let loadingText: LocalizedStringResource
	let emptyText: LocalizedStringResource
	let icon: String
	let load: () async -> Void
	let loadMore: (() async -> Void)?
	let hasMorePages: Bool
	let loadingMoreText: LocalizedStringResource
	@ViewBuilder let row: (Data.Element) -> Row

	init(
		state: LoadState<Data>,
		id: KeyPath<Data.Element, ID>,
		loadingText: LocalizedStringResource,
		emptyText: LocalizedStringResource,
		icon: String,
		load: @escaping () async -> Void,
		@ViewBuilder row: @escaping (Data.Element) -> Row
	) {
		self.state = state
		self.id = id
		self.loadingText = loadingText
		self.emptyText = emptyText
		self.icon = icon
		self.load = load
		self.loadMore = nil
		self.hasMorePages = false
		self.loadingMoreText = "Loading more"
		self.row = row
	}

	init(
		state: LoadState<Data>,
		id: KeyPath<Data.Element, ID>,
		loadingText: LocalizedStringResource,
		emptyText: LocalizedStringResource,
		icon: String,
		load: @escaping () async -> Void,
		loadMore: @escaping () async -> Void,
		hasMorePages: Bool,
		loadingMoreText: LocalizedStringResource = "Loading more",
		@ViewBuilder row: @escaping (Data.Element) -> Row
	) {
		self.state = state
		self.id = id
		self.loadingText = loadingText
		self.emptyText = emptyText
		self.icon = icon
		self.load = load
		self.loadMore = loadMore
		self.hasMorePages = hasMorePages
		self.loadingMoreText = loadingMoreText
		self.row = row
	}

	var body: some View {
		List {
			switch state {
			case .loading:
				LoadingView(loadingText, systemImage: icon)
			case .loaded(let data):
				loadedContent(data)
			case .failed(let failure):
				FailedView(failure)
			case .loadingMore(let data):
				loadedContent(data)
				LoadingView(loadingMoreText, systemImage: icon)
			case .failedMore(let data, let failure):
				loadedContent(data)
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

	@ViewBuilder
	private func loadedContent(_ data: Data) -> some View {
		if data.isEmpty {
			NoContentView(emptyText, systemImage: icon)
		} else {
			ForEach(data, id: id) { element in
				row(element)
					.onAppear {
						if let loadMore, hasMorePages, element[keyPath: id] == data.last?[keyPath: id] {
							Task {
								await loadMore()
							}
						}
					}
			}
		}
	}
}
