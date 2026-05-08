//
//  AuthMiddleware.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

#if os(Android)
	import Foundation
	import OpenAPIRuntime
	import HTTPTypes

	final class AuthenticationMiddleware: ClientMiddleware {
		private let token: String

		init(token: String) {
			self.token = token
		}

		func intercept(
			_ request: HTTPRequest,
			body: HTTPBody?,
			baseURL: URL,
			operationID: String,
			next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
		) async throws -> (HTTPResponse, HTTPBody?) {
			var modifiedRequest = request
			modifiedRequest.headerFields[.authorization] = "token \(token)"
			return try await next(modifiedRequest, body, baseURL)
		}
	}
#endif
