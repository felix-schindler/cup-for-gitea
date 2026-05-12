//
//  GiteaInstance.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import Foundation
import CryptoKit

struct GiteaInstance: Codable, Identifiable, Equatable {
	let host: String
	let token: String

	var id: String { host }

	var serverURL: URL {
		URL(string: "https://\(host)/api/v1")!
	}
}
