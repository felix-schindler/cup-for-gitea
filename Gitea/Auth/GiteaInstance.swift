//
//  GiteaInstance.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import Foundation

struct GiteaInstance: Identifiable, Equatable {
	let baseURL: URL
	let token: String

	var id: String { baseURL.absoluteString }

	var serverURL: URL {
		baseURL.appending(path: "api/v1", directoryHint: .isDirectory)
	}

	var displayURL: String {
		baseURL.absoluteString
	}

	init(baseURL: URL, token: String) {
		self.baseURL = baseURL
		self.token = token
	}

	init?(serverURLString: String, token: String) {
		guard let baseURL = Self.normalizedBaseURL(from: serverURLString) else {
			return nil
		}
		self.init(baseURL: baseURL, token: token)
	}

	static func normalizedBaseURL(from string: String) -> URL? {
		let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
		guard trimmed.isNotEmpty else { return nil }

		let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
		guard let url = URL(string: withScheme) else { return nil }

		return normalizedBaseURL(from: url)
	}

	static func normalizedBaseURL(from url: URL) -> URL? {
		guard let scheme = url.scheme?.lowercased(),
			["http", "https"].contains(scheme),
			let host = url.host(percentEncoded: false)?.lowercased(),
			host.isNotEmpty
		else {
			return nil
		}

		var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
		components?.scheme = scheme
		components?.host = host
		components?.user = nil
		components?.password = nil
		components?.query = nil
		components?.fragment = nil

		let normalizedPath = normalizedBasePath(url.path(percentEncoded: false))
		components?.path = normalizedPath.isEmpty ? "" : normalizedPath

		return components?.url
	}

	private static func normalizedBasePath(_ path: String) -> String {
		let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
		var trimmed = components

		if trimmed.suffix(2).map({ $0.lowercased() }) == ["api", "v1"] {
			trimmed.removeLast(2)
		}

		return trimmed.isEmpty ? "" : "/" + trimmed.joined(separator: "/")
	}
}

extension GiteaInstance: Codable {
	enum CodingKeys: String, CodingKey {
		case baseURL, token, host
	}

	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		token = try container.decode(String.self, forKey: .token)

		if let baseURL = try container.decodeIfPresent(URL.self, forKey: .baseURL),
			let normalized = Self.normalizedBaseURL(from: baseURL)
		{
			self.baseURL = normalized
			return
		}

		let host = try container.decode(String.self, forKey: .host)
		guard let baseURL = Self.normalizedBaseURL(from: host) else {
			throw DecodingError.dataCorruptedError(
				forKey: .host,
				in: container,
				debugDescription: "Invalid Gitea instance URL: \(host)"
			)
		}
		self.baseURL = baseURL
	}

	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(baseURL, forKey: .baseURL)
		try container.encode(token, forKey: .token)
	}
}
