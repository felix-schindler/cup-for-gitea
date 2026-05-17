import Foundation

enum LoadState<Value> {
	case loading
	case loaded(Value)
	case failed(Error)

	init(catching body: () async throws -> Value) async {
		do {
			self = .loaded(try await body())
		} catch {
			self = .failed(error)
		}
	}
}
