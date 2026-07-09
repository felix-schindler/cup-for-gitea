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
}
