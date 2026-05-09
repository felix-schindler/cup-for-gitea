//
//  Network.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import Foundation
import GiteaAPI

@MainActor
class Network {
	public static let shared = GiteaClient(
		serverURL: URL(string: "https://git.schindlerfelix.de/api/v1")!,
		token: "210f7287c4a374781d524c88314e639c9ef27e2c"
	)
}
