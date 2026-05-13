//
//  ReleaseView.swift
//  Gitea
//
//  Created by Felix Schindler on 13.05.26.
//

import SwiftUI
import Textual

struct ReleaseView: View {
	private let release: Components.Schemas.Release

	init(_ release: Components.Schemas.Release) {
		self.release = release
	}

	var body: some View {
		Section {
			VStack(alignment: .leading, spacing: 8) {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						SmallUserView(release.author)

						PillView(release.tagName, systemImage: Icons.topics.rawValue)

						if release.draft {
							PillView("Draft", systemImage: "pencil")
						}

						if release.prerelease {
							PillView("Pre-release", systemImage: "sparkles")
						}
					}
					.font(.footnote)
				}

				if release.body.isNotEmpty {
					StructuredText(markdown: release.body.emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			if release.assets.isNotEmpty || release.zipballUrl.isNotEmpty || release.tarballUrl.isNotEmpty {
				DisclosureGroup("Assets (\(release.assets.count))") {
					if release.assets.isNotEmpty {
						ForEach(release.assets, id: \.id) { asset in
							if let url = URL(string: asset.browserDownloadUrl) {
								Link(
									destination: url,
									label: {
										Label(
											"\(asset.name) (\(ByteFormatter.shared.format(asset.size)))",
											systemImage: "square.and.arrow.down"
										)
										.modifier {
											if #available(iOS 26.0, *) {
												$0.labelIconToTitleSpacing(5)
											}
										}
									}
								)
							} else {
								Text(asset.name)
							}
						}
					}

					if release.zipballUrl.isNotEmpty, let url = URL(string: release.zipballUrl) {
						Link("Source code (zip)", destination: url)
					}

					if release.tarballUrl.isNotEmpty, let url = URL(string: release.tarballUrl) {
						Link("Source code (tar.gz)", destination: url)
					}
				}
			}
		} header: {
			HStack {
				Text(release.name.isNotEmpty ? release.name.emojized() : release.tagName)
				if release.draft {
				}
				Spacer()
				Text(release.publishedAt.toString(timeStyle: .short))
					.font(.footnote)
			}
		}
		.swipeActions {
			if let url = URL(string: release.htmlUrl) {
				ShareLink(item: url)
			}
		}
	}
}
