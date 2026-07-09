//
//  GiteaClient.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public final class GiteaClient: Sendable {
	public let serverURL: URL
	public let token: String
	public let client: Client

	public init(serverURL: URL, token: String) {
		self.serverURL = serverURL
		self.token = token
		let urlSessionConfig = URLSessionConfiguration.default
		urlSessionConfig.httpAdditionalHeaders = [
			"Authorization": "token \(token)"
		]
		let session = URLSession(configuration: urlSessionConfig)
		self.client = Client(serverURL: serverURL, transport: URLSessionTransport(configuration: .init(session: session)))
	}
}
