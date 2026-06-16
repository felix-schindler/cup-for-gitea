//
//  ErrorExtensions.swift
//  Gitea
//
//  Created by Felix Schindler on 16.06.26.
//

import Foundation
import OpenAPIRuntime

extension Error {
	var userDescription: String {
		let inner: Error
		if let clientError = self as? ClientError {
			inner = clientError.underlyingError
		} else {
			inner = self
		}
		if let decodingError = inner as? DecodingError {
			return decodingErrorMessage(decodingError)
		}
		return inner.localizedDescription
	}
}

private func decodingErrorMessage(_ error: DecodingError) -> String {
	switch error {
	case .valueNotFound(_, let context):
		let key = context.codingPath.map(\.stringValue).joined(separator: ".")
		return "Required value missing at '\(key)'"
	case .keyNotFound(let key, _):
		return "Required key '\(key.stringValue)' not found"
	case .typeMismatch(_, let context):
		let key = context.codingPath.map(\.stringValue).joined(separator: ".")
		return "Unexpected value type at '\(key)'"
	case .dataCorrupted(let context):
		return context.debugDescription
	@unknown default:
		return error.localizedDescription
	}
}
