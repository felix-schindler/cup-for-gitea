//
//  Instances.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import Foundation

@MainActor
class InstanceManager {
	private static let userDefaults = UserDefaults.standard
	private static let instancesKey = "instances"
	private static let selectedKey = "selectedInstance"

	// This is a fallback which should hopefully never be used
	static let defaultInstance = GiteaInstance(baseURL: URL(string: "https://gitea.com")!, token: "")

	static var instances: [GiteaInstance] {
		get {
			guard let data = userDefaults.data(forKey: instancesKey),
				let instances = try? JSONDecoder().decode([GiteaInstance].self, from: data)
			else {
				return []
			}
			return instances
		}
		set {
			if let data = try? JSONEncoder().encode(newValue) {
				userDefaults.set(data, forKey: instancesKey)
			}
		}
	}

	static var selectedId: String? {
		get {
			userDefaults.string(forKey: selectedKey)
		}
		set {
			userDefaults.set(newValue, forKey: selectedKey)
		}
	}

	static var selected: GiteaInstance? {
		guard let id = selectedId else { return nil }
		return instances.first { $0.id == id }
	}

	static func add(_ instance: GiteaInstance) {
		var current = instances
		current.removeAll { $0.id == instance.id }
		current.append(instance)
		instances = current
		selectedId = instance.id
	}

	static func remove(_ instance: GiteaInstance) {
		var current = instances
		current.removeAll { $0.id == instance.id }
		instances = current

		if selectedId == instance.id {
			selectedId = current.last?.id
		}
	}

	static func select(_ instance: GiteaInstance) {
		selectedId = instance.id
	}

	static func update(_ instance: GiteaInstance) {
		remove(instance)
		add(instance)
	}
}
