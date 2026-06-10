//
//  RepoView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import OpenAPIRuntime
import SwiftUI
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
			let contents = try await Network.shared.client.repoGetRawFile(
				.init(
					path: .init(
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
			Section {
				HeaderRepoView(repo)
			}

			if repo.fork || repo.template || repo.mirror || repo.archived || repo.originalUrl.isNotEmpty {
				Section {
					VStack(alignment: .leading) {
						if repo.fork {
							Label("This repository is a fork of another repository.", systemImage: Icons.forks.rawValue)
						}
						if repo.template {
							Label("This repository is a template.", systemImage: "document.on.document")
						}
						if repo.mirror {
							Label("This repository is a mirror.", systemImage: "square.stack.3d.forward.dottedline")
							Text("Last updated at \(repo.mirrorUpdated.toString()); Inverval: \(repo.mirrorInterval)")
								.font(.footnote)
						}
						if repo.archived {
							Label("This repository has been archived on \(repo.archivedAt.toString()).", systemImage: "archivebox")
						}
						if let url = URL(string: repo.originalUrl) {
							Link(repo.originalUrl, destination: url)
								.font(.caption)
						}
					}.labelStyle(TrailingIconLabelStyle())
				}.foregroundStyle(.foreground)
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
						NavigationLink(destination: IssueSearchLoader(type: .issues, owner: repo.owner.login, repo: repo.name)) {
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
				}

				if repo.hasPullRequests {
					NavigationLink(destination: IssueSearchLoader(type: .pulls, owner: repo.owner.login, repo: repo.name)) {
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
				}

				DisclosureGroup(
					content: {
						NavigationLink("Collaborators") {
							UserSearchLoader(context: .repoCollaborators(owner: repo.owner.login, repo: repo.name))
						}
						NavigationLink("Labels") {
							LabelsLoader(owner: repo.owner.login, repo: repo.name)
						}
						NavigationLink("Milestones") {
							MilestonesLoader(owner: repo.owner.login, repo: repo.name)
						}
						NavigationLink("Worktime") {
							RepoWorktimeLoader(owner: repo.owner.login, repo: repo.name)
						}
						// if repo.hasProjects {
						// 	Text("Projects")
						// }
						if repo.hasWiki, let externalWiki = repo.externalWiki, let url = URL(string: externalWiki.externalWikiUrl) {
							Link("Wiki", destination: url)
						}
					},
					label: {
						Label("Plan", systemImage: "calendar.badge.checkmark")
					}
				)

				if repo.hasCode {
					DisclosureGroup(
						content: {
							NavigationLink("Code") {
								TreeLoader(owner: repo.owner.login, repo: repo.name, ref: repo.defaultBranch)
							}
							NavigationLink("Commits") {
								CommitsLoader(owner: repo.owner.login, repo: repo.name, ref: repo.defaultBranch)
							}
							NavigationLink("Branches") {
								BranchesLoader(owner: repo.owner.login, repo: repo.name)
							}
							NavigationLink("Tags") {
								TagsLoader(owner: repo.owner.login, repo: repo.name)
							}
						},
						label: {
							Label("Repository", systemImage: Icons.code.rawValue)
						}
					)
				}

				if repo.hasReleases || repo.hasActions || repo.hasPackages {
					DisclosureGroup(
						content: {
							if repo.hasActions {
								NavigationLink("Actions") {
									ActionsLoader(owner: repo.owner.login, repo: repo.name)
								}
							}
							if repo.hasReleases {
								NavigationLink("Releases") {
									ReleaseLoader(owner: repo.owner.login, repo: repo.name)
								}
							}
							if repo.hasPackages {
								NavigationLink("Packages") {
									RepoPackageLoader(owner: repo.owner.login, repo: repo.name)
								}
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
		}.refreshable {
			await load()
		}.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Menu("More", systemImage: "ellipsis") {
					if let url = URL(string: repo.htmlUrl) {
						Section {
							ShareLink(item: url)
						}
					}

					Section("Clone code") {
						Button("Copy SSH URL") {
							UIPasteboard.general.string = repo.sshUrl
							HapticFeedback.notify(.success)
						}
						Button("Copy HTTPS URL") {
							UIPasteboard.general.string = repo.cloneUrl
							HapticFeedback.notify(.success)
						}
					}
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				Menu("Create", systemImage: "plus") {
					if repo.hasIssues, repo.externalTracker == nil {
						NavigationLink(destination: NewIssueView(owner: repo.owner.login, repo: repo.name)) {
							Label("New Issue", systemImage: Icons.issues.rawValue)
						}
					}
					if repo.hasPullRequests {
						NavigationLink(destination: NewPullRequestView(owner: repo.owner.login, repo: repo.name)) {
							Label("New Pull Request", systemImage: Icons.pull_requests.rawValue)
						}
					}
					NavigationLink(destination: NewLabelView(owner: repo.owner.login, repo: repo.name)) {
						Label("New Label", systemImage: Icons.topics.rawValue)
					}
					NavigationLink(destination: NewMilestoneView(owner: repo.owner.login, repo: repo.name)) {
						Label("New Milestone", systemImage: Icons.milestones.rawValue)
					}
					if repo.hasReleases {
						NavigationLink(destination: NewReleaseView(owner: repo.owner.login, repo: repo.name)) {
							Label("New Release", systemImage: "flag")
						}
					}
				}
			}
		}
		.navigationTitle(repo.fullName)
		.navigationBarTitleDisplayMode(.inline)
	}
}
