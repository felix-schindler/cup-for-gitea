import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

public final class GiteaClient: Sendable {
    public let serverURL: URL
    public let token: String?
    public let client: Client

    public init(serverURL: URL, token: String? = nil) {
        self.serverURL = serverURL
        self.token = token

        let transport: URLSessionTransport
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
        self.client = Client(serverURL: serverURL, transport: transport)
    }
}
