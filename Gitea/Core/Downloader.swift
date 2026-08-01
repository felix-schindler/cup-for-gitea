//
//  Downloader.swift
//  Gitea
//
//  Created by Felix Schindler on 01.08.26.
//

import SwiftUI
import UIKit

enum Downloader {
	@MainActor
	static func archive(from url: URL, fileName: String? = nil) async throws -> URL {
		var request = URLRequest(url: url)
		request.setValue("token \(Network.shared.token)", forHTTPHeaderField: "Authorization")
		let (data, _) = try await URLSession.shared.data(for: request)
		let tempURL = FileManager.default.temporaryDirectory
			.appendingPathComponent(fileName ?? url.lastPathComponent)
		try data.write(to: tempURL)
		return tempURL
	}

	@MainActor
	static func presentShareSheet(for url: URL) {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			let root = windowScene.windows.first?.rootViewController
		else { return }
		let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
		root.present(vc, animated: true)
	}
}

struct DownloadArchiveButton<Label: View>: View {
	let url: URL
	let fileName: String?
	@ViewBuilder let label: () -> Label

	@State private var downloading = false
	@State private var showError = false
	@State private var error: Error?

	init(url: URL, fileName: String? = nil, @ViewBuilder label: @escaping () -> Label) {
		self.url = url
		self.fileName = fileName
		self.label = label
	}

	var body: some View {
		Button {
			downloading = true
			Task {
				defer { downloading = false }
				do {
					let file = try await Downloader.archive(from: url, fileName: fileName)
					Downloader.presentShareSheet(for: file)
				} catch let downloadError {
					error = downloadError
					showError = true
				}
			}
		} label: {
			if downloading {
				ProgressView()
					.controlSize(.small)
			} else {
				label()
			}
		}
		.disabled(downloading)
		.alert(
			"Download failed", isPresented: $showError,
			actions: {
				Button("OK") { error = nil }
			},
			message: {
				Text(error?.localizedDescription ?? "")
			}
		)
	}
}
