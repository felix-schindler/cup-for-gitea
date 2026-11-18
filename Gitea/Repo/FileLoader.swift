//
//  FileLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import AVKit
import SwiftUI
import Textual

struct FileLoader: View {
	private static let confirmThreshold: Int64 = 3 * 1024 * 1024

	private enum Phase {
		case loading
		case ready(size: Int64)
		case downloading(received: Int64, total: Int64)
		case loaded
		case failed(Error)
	}

	private let owner: String
	private let repo: String
	private let filePath: String
	private let ref: String
	private let fileExtension: String

	@Environment(\.colorScheme) private var colorScheme

	@State private var phase: Phase = .loading
	@State private var localURL: URL?
	@State private var text: String?
	@State private var image: UIImage?

	init(owner: String, repo: String, filePath: String, ref: String) {
		self.owner = owner
		self.repo = repo
		self.filePath = filePath
		self.ref = ref
		self.fileExtension = filePath.components(separatedBy: ".").last?.lowercased() ?? ""
	}

	private var fileName: String {
		filePath.components(separatedBy: "/").last ?? filePath
	}

	private var rawURL: URL {
		Network.baseURL.appending(path: "api/v1/repos/\(owner)/\(repo)/raw/\(ref)/\(filePath)")
	}

	private var isPDF: Bool {
		Formats.pdfFormats.contains(fileExtension)
	}

	private var isVideo: Bool {
		Formats.videoFormats.contains(fileExtension)
	}

	private var isLoaded: Bool {
		if case .loaded = phase {
			return true
		}
		return false
	}

	private var icon: String {
		if Formats.audioFormats.contains(fileExtension) || isVideo {
			return "play"
		} else if Formats.imageFormats.contains(fileExtension) {
			return "photo"
		} else if isPDF {
			return "doc.richtext"
		} else {
			return "document"
		}
	}

	private func probe() async {
		// Still on disk? Reuse it. This also covers a file that was cleared from
		// Settings while this screen was open.
		if let localURL, FileManager.default.fileExists(atPath: localURL.path) {
			phase = .loaded
			return
		}

		localURL = nil
		image = nil
		text = nil
		phase = .loading

		do {
			let response = try await Network.shared.client.repoGetContentsExt(
				path: .init(owner: owner, repo: repo, filepath: filePath),
				query: .init(ref: ref)
			).ok.body.json

			// No size to show, so we can't ask — just download it.
			let size = response.fileContents?.size
			guard let size, size >= Self.confirmThreshold else {
				await loadFile(expectedSize: size)
				return
			}

			phase = .ready(size: size)
		} catch {
			await loadFile()
		}
	}

	private func loadFile(expectedSize: Int64? = nil) async {
		if !isLoaded {
			phase = .loading
		}

		do {
			let url = try await Downloader.download(
				from: rawURL, fileName: fileName, expectedSize: expectedSize
			) { received, total in
				// Below the threshold a file arrives instantly, so don't flash a
				// bar at it — and a refresh keeps the existing preview visible.
				guard total >= Self.confirmThreshold, !isLoaded else {
					return
				}
				phase = .downloading(received: received, total: total)
			}

			localURL = url
			resolvePreview(from: url)
			phase = .loaded
		} catch {
			localURL = nil
			image = nil
			text = nil
			phase = .failed(error)
		}
	}

	private func resolvePreview(from url: URL) {
		if isPDF || isVideo {
			image = nil
			text = nil
		} else if Formats.imageFormats.contains(fileExtension) {
			image = UIImage(contentsOfFile: url.path)
			text = nil
		} else {
			image = nil
			text = (try? String(contentsOf: url, encoding: .utf8))
		}
	}

	var body: some View {
		Group {
			if case .failed(let error) = phase {
				FailedView(error)
			} else if Formats.audioFormats.contains(fileExtension) {
				unavailable("Can't preview this \(fileExtension) audio file", systemImage: "play")
			} else if Formats.binaryFormats.contains(fileExtension) {
				unavailable("Can't preview this \(fileExtension) file", systemImage: "doc.zipper")
			} else if isLoaded, let localURL {
				if isPDF {
					PDFPreview(url: localURL)
				} else {
					ScrollView {
						VStack(alignment: .leading) {
							preview(localURL)
							Spacer()
						}
						.padding(.horizontal)
						.frame(maxWidth: .infinity)
					}
					.refreshable {
						await loadFile()
					}
				}
			} else {
				pending
			}
		}
		.task {
			await probe()
		}
		.toolbar {
			if let localURL {
				ShareLink(item: localURL) {
					Label("Share", systemImage: Icons.share.rawValue)
				}
			}
		}
		.navigationTitle(filePath)
		.navigationBarTitleDisplayMode(.inline)
	}

	@ViewBuilder
	private func preview(_ url: URL) -> some View {
		if isVideo {
			VideoPlayer(player: AVPlayer(url: url))
		} else if Formats.imageFormats.contains(fileExtension) {
			if let image {
				Image(uiImage: image)
					.resizable()
					.scaledToFit()
					.cornerRadius(10)
			} else {
				unavailable("Can't preview this \(fileExtension) file", systemImage: "photo")
			}
		} else if let text {
			if fileExtension == "md" || fileExtension == "markdown" {
				StructuredText(markdown: text.emojized())
					.textual.structuredTextStyle(.gitHub)
					.textual.textSelection(.enabled)
			} else {
				CodeTextView(
					text,
					language: fileExtension,
					colorScheme: colorScheme,
					fontSize: 12
				)
			}
		} else {
			unavailable("Can't preview this \(fileExtension) file", systemImage: "document")
		}
	}

	@ViewBuilder
	private var pending: some View {
		VStack(spacing: 12) {
			Image(systemName: icon)
				.resizable()
				.scaledToFit()
				.foregroundStyle(.gray)
				.frame(width: 50, height: 50)

			switch phase {
			case .ready(let size):
				Text(ByteFormatter.shared.format(size))
					.font(.title2.bold())
				Button {
					Task {
						await loadFile(expectedSize: size)
					}
				} label: {
					Label("Download", systemImage: "arrow.down.circle")
				}
				.adaptiveButtonStyleProminent()
			case .downloading(let received, let total):
				ProgressView(value: total > 0 ? Double(received) / Double(total) : nil)
					.frame(maxWidth: 220)
				Text("\(ByteFormatter.shared.format(received)) of \(ByteFormatter.shared.format(total))")
					.font(.callout)
					.monospacedDigit()
			default:
				ProgressView()
			}
		}
		.padding()
		.frame(maxWidth: .infinity, minHeight: 100)
	}

	private func unavailable(_ message: LocalizedStringResource, systemImage: String) -> some View {
		VStack {
			Image(systemName: systemImage)
				.resizable()
				.scaledToFit()
				.foregroundStyle(.gray)
				.frame(width: 50, height: 50)
			Text(message)
		}
		.padding()
		.frame(maxWidth: .infinity, minHeight: 100)
	}
}
