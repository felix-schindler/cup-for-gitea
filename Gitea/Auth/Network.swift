//
//  Network.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import Foundation

@MainActor
class Network {
	public static var shared: GiteaClient {
		let instance = InstanceManager.selected ?? InstanceManager.defaultInstance
		return GiteaClient(serverURL: instance.serverURL, token: instance.token)
	}
}
