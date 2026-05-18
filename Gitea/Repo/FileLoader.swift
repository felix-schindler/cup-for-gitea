//
//  FileLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 18.05.26.
//

import OpenAPIRuntime
import SwiftUI
import Textual

struct FileLoader: View {
	let owner: String
	let repo: String
	let filePath: String
	let ref: String

	@Environment(\.colorScheme) private var colorScheme

	@State private var content: String?
	@State private var error: Error?
	@State private var isLoading = true

	private var fileExtension: String {
		filePath.components(separatedBy: ".").last?.lowercased() ?? ""
	}

	private func load() async {
		isLoading = true
		error = nil
		do {
			let raw = try await Network.shared.client.repoGetRawFile(
				.init(
					path: .init(owner: owner, repo: repo, filepath: "\(ref)/\(filePath)")
				)
			).ok.body.plainText
			content = try await String(collecting: raw, upTo: 2 * 1024 * 1024)
		} catch {
			self.error = error
		}
		isLoading = false
	}

	var body: some View {
		ScrollView {
			VStack(alignment: .leading) {
				if isLoading {
					LoadingView("Loading file", systemImage: "document")
						.padding()
				} else if let error {
					FailedView(error)
						.padding()
				} else if let content {
					if fileExtension == "md" || fileExtension == "markdown" {
						StructuredText(markdown: content.emojized())
							.textual.structuredTextStyle(.gitHub)
							.textual.textSelection(.enabled)
							.padding()
					} else {
						CodeTextView(
							content,
							language: fileExtension,
							colorScheme: colorScheme,
							fontSize: 12
						)
						.padding()
					}
				}

				Spacer()
			}
			.frame(maxWidth: .infinity)
		}
		.task {
			await load()
		}
		.refreshable {
			await load()
		}
		.navigationTitle(filePath)
		.navigationBarTitleDisplayMode(.inline)
	}
}
