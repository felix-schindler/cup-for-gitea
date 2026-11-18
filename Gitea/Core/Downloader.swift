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
		try await download(from: url, fileName: fileName ?? url.lastPathComponent)
	}

	/// Streams the file straight to the temporary file cache. Progress is reported
	/// as `(received, total)`, with `total` being `-1` when the server sends no length.
	@MainActor
	static func download(
		from url: URL,
		fileName: String,
		expectedSize: Int64? = nil,
		onProgress: (@MainActor (Int64, Int64) -> Void)? = nil
	) async throws -> URL {
		var request = URLRequest(url: url)
		request.setValue("token \(Network.shared.token)", forHTTPHeaderField: "Authorization")

		FileCache.purge()
		let destination = FileCache.destination(for: fileName)
		let delegate = ProgressDelegate(
			destination: destination, expectedSize: expectedSize, onProgress: onProgress)
		let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
		defer { session.finishTasksAndInvalidate() }
		try await delegate.start(request: request, in: session)
		return destination
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

private final class ProgressDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
	private let destination: URL
	private let expectedSize: Int64?
	private let onProgress: (@MainActor (Int64, Int64) -> Void)?
	private var continuation: CheckedContinuation<Void, Error>?

	init(destination: URL, expectedSize: Int64?, onProgress: (@MainActor (Int64, Int64) -> Void)?) {
		self.destination = destination
		self.expectedSize = expectedSize
		self.onProgress = onProgress
	}

	/// Callbacks arrive on the session's serial delegate queue, so the continuation
	/// is set before the task starts and only touched there afterwards.
	func start(request: URLRequest, in session: URLSession) async throws {
		try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
			session.downloadTask(with: request).resume()
		}
	}

	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64,
		totalBytesExpectedToWrite: Int64
	) {
		guard let onProgress else { return }
		// Gitea usually streams chunked without a Content-Length, so fall back to
		// the size from the contents metadata.
		let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : (expectedSize ?? -1)
		Task { @MainActor in
			onProgress(totalBytesWritten, total)
		}
	}

	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		guard let http = downloadTask.response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
			finish(throwing: URLError(.badServerResponse))
			return
		}

		do {
			try FileManager.default.createDirectory(
				at: destination.deletingLastPathComponent(),
				withIntermediateDirectories: true
			)
			try? FileManager.default.removeItem(at: destination)
			try FileManager.default.moveItem(at: location, to: destination)
			finish()
		} catch {
			finish(throwing: error)
		}
	}

	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		// A successful download finishes in `didFinishDownloadingTo`; this only
		// reports transport failures and cancellation.
		if let error {
			finish(throwing: error)
		}
	}

	private func finish(throwing error: Error? = nil) {
		guard let continuation else { return }
		self.continuation = nil
		if let error {
			continuation.resume(throwing: error)
		} else {
			continuation.resume()
		}
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
