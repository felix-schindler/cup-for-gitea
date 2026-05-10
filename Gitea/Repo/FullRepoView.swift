//
//  RepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI
import OpenAPIRuntime
import Textual

struct FullRepoView: View {
	@State private var readmeContents: String?
	@State private var copied = false
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	private func load() async {
		do {
			let contents = try await Network.shared.client.repoGetRawFile(.init(path: .init(
				owner: repo.owner.login,
				repo: repo.name,
				filepath: "README.md"))
			).ok.body.plainText
			
			// Collect the entire HTTP body into a single String, limiting to 2 MB
			let stringContents = try await String(collecting: contents, upTo: 2 * 1024 * 1024)
			readmeContents = stringContents
		} catch {
			print(error)
		}
	}

	var body: some View {
		List {
			if repo.fork || repo.template || repo.mirror || repo.archived || repo.originalUrl.isNotEmpty {
				Section {
					VStack(alignment: .leading) {
						if repo.fork {
							Text("This repository is a fork of another repository.")
						}
						if repo.template {
							Text("This repository is a template.")
						}
						if repo.mirror {
							Text("This repository is a mirror.")
							Text("Last updated at \(repo.mirrorUpdated.toString()); Inverval: \(repo.mirrorInterval)")
								.font(.footnote)
						}
						if repo.archived {
							Text("This repository has been archived on \(repo.archivedAt.toString()).")
						}
						if repo.originalUrl.isNotEmpty {
							Link(repo.originalUrl, destination: URL(string: repo.originalUrl)!)
								.font(.caption)
						}
					}
				}
				.listRowBackground(Color.yellow)
				.foregroundStyle(Color.black)
			}

			Section {
				HeaderRepoView(repo)
			}

			Section {
				if repo.hasIssues {
					if let externalTracker = repo.externalTracker?.externalTrackerUrl,
						let url = URL(string: externalTracker)
					{
						Link(
							destination: url,
							label: {
								Label("Issues", systemImage: Icons.issues.rawValue)
							})
					} else {
						Label(
							title: {
								HStack {
									Text("Issues")
									Spacer()
									Text("\(repo.openIssuesCount)")
								}
							},
							icon: {
								Image(systemName: Icons.issues.rawValue)
							})
					}
				}

				if repo.hasPullRequests {
					Label(
						title: {
							HStack {
								Text("Pull Requests")
								Spacer()
								Text("\(repo.openPrCounter)")
							}
						},
						icon: {
							Image(systemName: Icons.pull_requests.rawValue)
						})
				}
				
				DisclosureGroup(
					content: {
						Text("Members")
						Text("Labels")
					},
					label: {
						Label("Manage", systemImage: "person.2")
					}
				)

				DisclosureGroup(
					content: {
						Text("Milestones")
						if repo.hasProjects {
							Text("Projects")
						}
						if repo.hasWiki {
							Text("Wiki")
						}
					},
					label: {
						Label("Plan", systemImage: "calendar.badge.checkmark")
					}
				)

				if repo.hasCode {
					DisclosureGroup(content: {
						Text("Code")
						Text("Commits")
						Text("Branches")
						Text("Tags")
					}, label: {
						Label("Repository", systemImage: Icons.code.rawValue)
					})
				}

				if repo.hasReleases || repo.hasActions || repo.hasPackages {
					DisclosureGroup(
						content: {
							if repo.hasActions {
								Text("Actions")
							}
							if repo.hasReleases {
								Text("Releases")
							}
							if repo.hasPackages {
								Text("Packages")
							}
						},
						label: {
							Label("Build", systemImage: "flag")
						}
					)
				}
			}
			
			if let readmeContents, readmeContents.isNotEmpty {
				Section {
					// TODO: Fix base url — should be host/{owner}/{repo}
					StructuredText(markdown: readmeContents.emojized(), baseURL: Network.shared.serverURL)
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			}
		}.task {
			await load()
		}.toolbar {
			Menu("More", systemImage: "ellipsis") {
				Section {
					ShareLink(
						item: URL(string: repo.htmlUrl)!,
						label: {
							Label("Share", systemImage: Icons.share.rawValue)
						})
				}

				// TODO: Add haptic feedback
				Section("Clone code") {
					Button("Copy SSH URL") {
						UIPasteboard.general.string = repo.sshUrl
					}
					Button("Copy HTTPS URL") {
						UIPasteboard.general.string = repo.sshUrl
					}
				}
			}
		}
		.navigationTitle(repo.fullName)
		.navigationBarTitleDisplayMode(.inline)
	}
}
