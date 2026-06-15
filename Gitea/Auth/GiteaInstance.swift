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
}

extension GiteaInstance: Codable {
	enum CodingKeys: String, CodingKey {
		case baseURL, token, host
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		token = try container.decode(String.self, forKey: .token)
		
		if let baseURL = try container.decodeIfPresent(URL.self, forKey: .baseURL) {
			self.baseURL = baseURL
		} else {
			let host = try container.decode(String.self, forKey: .host)
			guard let url = URL(string: "https://\(host)") else {
				throw DecodingError.dataCorruptedError(
					forKey: .host,
					in: container,
					debugDescription: "Invalid host: \(host)"
				)
			}
			baseURL = url
		}
	}
	
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(baseURL, forKey: .baseURL)
		try container.encode(token, forKey: .token)
	}
}
