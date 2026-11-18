//
//  CacheView.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import SwiftUI

struct CacheView: View {
	@State private var urlMemoryUsage = URLCache.shared.currentMemoryUsage
	@State private var urlDiskUsage = URLCache.shared.currentDiskUsage
	@State private var avatarMemoryUsage = URLCache.avatarCache.currentMemoryUsage
	@State private var avatarDiskUsage = URLCache.avatarCache.currentDiskUsage
	@State private var fileSize = FileCache.size()

	var body: some View {
		Form {
			Section("URL cache") {
				Text("In memory: \(ByteFormatter.shared.format(Int64(urlMemoryUsage)))")
				Text("On disk: \(ByteFormatter.shared.format(Int64(urlDiskUsage)))")
				Button("Clear cache", systemImage: "trash", role: .destructive) {
					URLCache.shared.removeAllCachedResponses()
					urlMemoryUsage = URLCache.shared.currentMemoryUsage
					urlDiskUsage = URLCache.shared.currentDiskUsage
					HapticFeedback.notify(.success)
				}
			}

			Section("Avatar cache") {
				Text("In memory: \(ByteFormatter.shared.format(Int64(avatarMemoryUsage)))")
				Text("On disk: \(ByteFormatter.shared.format(Int64(avatarDiskUsage)))")
				Button("Clear cache", systemImage: "trash", role: .destructive) {
					URLCache.avatarCache.removeAllCachedResponses()
					avatarMemoryUsage = URLCache.avatarCache.currentMemoryUsage
					avatarDiskUsage = URLCache.avatarCache.currentDiskUsage
					HapticFeedback.notify(.success)
				}
			}

			Section("Downloaded files") {
				Text("Temporary files: \(ByteFormatter.shared.format(fileSize))")
				Button("Clear cache", systemImage: "trash", role: .destructive) {
					FileCache.clear()
					fileSize = FileCache.size()
					HapticFeedback.notify(.success)
				}
			}
		}
		.navigationTitle("Caches")
	}
}
