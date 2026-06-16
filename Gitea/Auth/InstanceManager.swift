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

	static let minimumRequiredVersion = "1.26.0"

	private static let acknowledgedVersionWarningsKey = "acknowledgedVersionWarnings"

	private static var acknowledgedVersionWarnings: Set<String> {
		get {
			guard let data = userDefaults.data(forKey: acknowledgedVersionWarningsKey),
				let set = try? JSONDecoder().decode(Set<String>.self, from: data)
			else { return [] }
			return set
		}
		set {
			if let data = try? JSONEncoder().encode(newValue) {
				userDefaults.set(data, forKey: acknowledgedVersionWarningsKey)
			}
		}
	}

	static func acknowledgeVersionWarning(for host: String, serverVersion: String) {
		var current = acknowledgedVersionWarnings
		current.insert("\(host):\(minimumRequiredVersion):\(serverVersion)")
		acknowledgedVersionWarnings = current
	}

	static func shouldShowVersionWarning(for host: String, serverVersion: String) -> Bool {
		!acknowledgedVersionWarnings.contains("\(host):\(minimumRequiredVersion):\(serverVersion)")
	}

	static func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
		let s1 = v1.hasPrefix("v") ? String(v1.dropFirst()) : v1
		let s2 = v2.hasPrefix("v") ? String(v2.dropFirst()) : v2
		let parts1 = s1.split(separator: ".").compactMap { Int($0) }
		let parts2 = s2.split(separator: ".").compactMap { Int($0) }

		for i in 0..<max(parts1.count, parts2.count) {
			let p1 = i < parts1.count ? parts1[i] : 0
			let p2 = i < parts2.count ? parts2[i] : 0
			if p1 < p2 { return .orderedAscending }
			if p1 > p2 { return .orderedDescending }
		}
		return .orderedSame
	}

	static var instances: [GiteaInstance] {
		get {
			guard let data = userDefaults.data(forKey: instancesKey),
				let instances = try? JSONDecoder().decode([GiteaInstance].self, from: data)
			else {
				return []
			}
			if let selectedId,
				!instances.contains(where: { $0.id == selectedId }),
				let migratedId = GiteaInstance.normalizedBaseURL(from: selectedId)?.absoluteString,
				instances.contains(where: { $0.id == migratedId })
			{
				self.selectedId = migratedId
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
