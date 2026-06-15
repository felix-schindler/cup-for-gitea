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
	public let baseURL: URL
	public let token: String
	public let client: Client

	public init(baseURL: URL, token: String) {
		self.baseURL = baseURL
		self.token = token

		let transport: any ClientTransport
		let urlSessionConfig = URLSessionConfiguration.default
		urlSessionConfig.httpAdditionalHeaders = [
			"Authorization": "token \(token)"
		]
		let session = URLSession(configuration: urlSessionConfig)
		transport = URLSessionTransport(
			configuration: .init(session: session)
		)

		self.client = Client(serverURL: baseURL.appending(path: "api/v1", directoryHint: .isDirectory), transport: transport)
	}
}
