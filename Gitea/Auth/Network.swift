//
//  Network.swift
//  cup-gitea
//
//  Created by Felix Schindler on 08.05.26.
//

import Foundation

@MainActor
class Network {
	private static var _client: GiteaClient?
	private static var _instanceKey: String?

	public static var baseURL: URL {
		(InstanceManager.selected ?? InstanceManager.defaultInstance).baseURL
	}

	public static var shared: GiteaClient {
		let instance = InstanceManager.selected ?? InstanceManager.defaultInstance
		let key = "\(instance.baseURL.absoluteString):\(instance.token)"
		if let client = _client, _instanceKey == key {
			return client
		}
		let client = GiteaClient(serverURL: instance.serverURL, token: instance.token)
		_client = client
		_instanceKey = key
		return client
	}
}
