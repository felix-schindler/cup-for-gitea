import Foundation
import OpenAPIRuntime

#if os(Android)
	import OpenAPIAsyncHTTPClient
#else
	import OpenAPIURLSession
#endif

public final class GiteaClient: Sendable {
	public let serverURL: URL
	public let token: String?
	public let client: Client

	public init(serverURL: URL, token: String? = nil) {
		self.serverURL = serverURL
		self.token = token

		let transport: any ClientTransport
		var middlewares: [any ClientMiddleware] = []

		#if os(Android)
			transport = AsyncHTTPClientTransport(
				configuration: AsyncHTTPClientTransport.Configuration()
			)

			if let token {
				middlewares.append(AuthenticationMiddleware(token: token))
			}
		#else
			if let token {
				let urlSessionConfig = URLSessionConfiguration.default
				urlSessionConfig.httpAdditionalHeaders = [
					"Authorization": "token \(token)"
				]
				let session = URLSession(configuration: urlSessionConfig)
				transport = URLSessionTransport(
					configuration: .init(session: session)
				)
			} else {
				transport = URLSessionTransport()
			}
		#endif
		self.client = Client(serverURL: serverURL, transport: transport, middlewares: middlewares)
	}
}
