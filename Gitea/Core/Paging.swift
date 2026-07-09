//
//  Paging.swift
//  Gitea
//
//  Created by Felix Schindler on 09.07.26.
//

import Foundation

struct Paging {
	var page = 1
	var hasMore = true
	var isLoading = false

	mutating func reset() {
		page = 1
		hasMore = true
		isLoading = false
	}

	func nextPage<T>(state currentState: LoadState<[T]>, limit: Int, fetch: (Int) async throws -> [T]) async -> (LoadState<[T]>, Paging) {
		guard !isLoading, hasMore else { return (currentState, self) }
		var p = self
		p.isLoading = true
		defer { p.isLoading = false }
		let current: [T]
		if case .loaded(let items) = currentState {
			current = items
		} else {
			current = []
		}
		do {
			let results = try await fetch(p.page)
			guard !Task.isCancelled else { return (currentState, p) }
			if results.count < limit { p.hasMore = false } else { p.page += 1 }
			return (.loaded(current + results), p)
		} catch {
			guard !Task.isCancelled else { return (currentState, p) }
			return (current.isEmpty ? .failed(error) : .failedMore(current, error), p)
		}
	}
}
