import Foundation

enum LoadState<Value> {
	case loading
	case loaded(Value)
	case loadingMore(Value)
	case failed(Error)
	case failedMore(Value, Error)

	var value: Value? {
		switch self {
		case .loaded(let v), .loadingMore(let v), .failedMore(let v, _): v
		case .loading, .failed: nil
		}
	}

	init(catching body: () async throws -> Value) async {
		do {
			self = .loaded(try await body())
		} catch {
			self = .failed(error)
		}
	}
}
