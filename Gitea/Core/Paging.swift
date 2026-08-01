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

	// Callers set `isLoading = true` before awaiting this, so concurrent
	// calls (refresh + loadMore) are blocked instead of writing back stale pages.
	func nextPage<T>(state currentState: LoadState<[T]>, limit: Int, reset: Bool = false, fetch: (Int) async throws -> [T]) async -> (LoadState<[T]>, Paging) {
		guard hasMore else { return (currentState, self) }
		var p = self
		let current = (reset ? nil : currentState.value) ?? []
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
