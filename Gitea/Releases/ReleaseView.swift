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
			VStack(alignment: .leading) {
				ScrollView(.horizontal, showsIndicators: false) {
					HStack {
						if let author = release.author {
							SmallUserView(author)
						}

						PillView(verbatim: release.tagName ?? "", systemImage: Icons.topics.rawValue)

						if release.draft == true {
							PillView("Draft", systemImage: "pencil")
						}

						if release.prerelease == true {
							PillView("Pre-release", systemImage: "sparkles")
						}
					}
					.font(.footnote)
				}

				if release.body?.isNotEmpty == true {
					StructuredText(markdown: (release.body ?? "").emojized())
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}

			if release.assets?.isNotEmpty == true || release.zipballUrl?.isNotEmpty == true || release.tarballUrl?.isNotEmpty == true {
				DisclosureGroup("Assets (\(release.assets?.count ?? 0))") {
					if release.assets?.isNotEmpty == true {
						ForEach(release.assets ?? [], id: \.id) { asset in
							if let urlString = asset.browserDownloadUrl, let url = URL(string: urlString) {
								DownloadArchiveButton(url: url, fileName: asset.name) {
									Label(
										"\(asset.name ?? "") (\(ByteFormatter.shared.format(asset.size ?? 0)))",
										systemImage: "square.and.arrow.down"
									)
									.modifier {
										if #available(iOS 26.0, *) {
											$0.labelIconToTitleSpacing(5)
										}
									}
								}
							} else {
								Text(asset.name ?? "")
							}
						}
					}

					if let zipballUrl = release.zipballUrl, zipballUrl.isNotEmpty, let url = URL(string: zipballUrl) {
						DownloadArchiveButton(url: url) {
							Label("Source code (zip)", systemImage: "doc.zipper")
						}
					}

					if let tarballUrl = release.tarballUrl, tarballUrl.isNotEmpty, let url = URL(string: tarballUrl) {
						DownloadArchiveButton(url: url) {
							Label("Source code (tar.gz)", systemImage: "doc.zipper")
						}
					}
				}
			}
		} header: {
			HStack {
				Text((release.name?.isNotEmpty == true ? release.name ?? "" : release.tagName ?? "").emojized())
				Spacer()
				Text(release.publishedAt?.toString(timeStyle: .short) ?? "")
					.font(.footnote)
			}
		}
		.swipeActions {
			if let htmlUrl = release.htmlUrl, let url = URL(string: htmlUrl) {
				ShareLink(item: url)
			}
		}
	}
}
