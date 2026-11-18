//
//  FileCache.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import Foundation

/// Temporary files downloaded for preview and sharing. Everything here is disposable.
enum FileCache {
	private static var root: URL {
		FileManager.default.temporaryDirectory
			.appendingPathComponent("cup-files", isDirectory: true)
	}

	/// A fresh, empty destination for one downloaded file.
	static func destination(for fileName: String) -> URL {
		let name = fileName.split(separator: "/").last.map(String.init) ?? ""
		let safeName = name.isEmpty || name == "." || name == ".." ? "file" : name
		return
			root
			.appendingPathComponent(UUID().uuidString, isDirectory: true)
			.appendingPathComponent(safeName)
	}

	static func purge() {
		let staleBefore = Date().addingTimeInterval(-24 * 60 * 60)

		guard
			let entries = try? FileManager.default.contentsOfDirectory(
				at: root,
				includingPropertiesForKeys: [.contentModificationDateKey]
			)
		else {
			return
		}

		for entry in entries {
			let modified = try? entry.resourceValues(forKeys: [.contentModificationDateKey])
				.contentModificationDate
			if let modified, modified < staleBefore {
				try? FileManager.default.removeItem(at: entry)
			}
		}
	}

	/// Total bytes currently on disk. Purges stale entries first so the number is honest.
	static func size() -> Int64 {
		purge()

		guard
			let enumerator = FileManager.default.enumerator(
				at: root,
				includingPropertiesForKeys: [.fileSizeKey]
			)
		else {
			return 0
		}

		var total: Int64 = 0
		for case let url as URL in enumerator {
			total += Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
		}
		return total
	}

	static func clear() {
		try? FileManager.default.removeItem(at: root)
	}
}
