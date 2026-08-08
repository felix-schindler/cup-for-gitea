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
	@State private var readmeError: Error?
	@State private var readmeReload = 0
	@State private var copied = false
	private let repo: Components.Schemas.Repository

	init(_ repo: Components.Schemas.Repository) {
		self.repo = repo
	}

	private var owner: String { repo.owner?.login ?? "" }
	private var repoName: String { repo.name ?? "" }
	private var defaultBranch: String { repo.defaultBranch ?? "" }

	private func load() async {
		do {
			let response = try await Network.shared.client.repoGetRawFile(
				.init(
					path: .init(
						owner: owner,
						repo: repoName,
						filepath: "README.md"))
			)
			switch response {
			case .ok(let ok):
				// Collect the entire HTTP body into a single String, limiting to 2 MB
				readmeContents = try await String(collecting: ok.body.plainText, upTo: 2 * 1024 * 1024)
				readmeError = nil
			case .notFound:
				// No README in this repo — not an error.
				readmeContents = nil
				readmeError = nil
			default:
				readmeContents = nil
				readmeError = ReadmeError.undocumented
			}
		} catch is CancellationError {
			// .task(id:) retry restarted this; ignore.
		} catch {
			readmeError = error
		}
	}

	enum ReadmeError: LocalizedError {
		case undocumented

		var errorDescription: String? {
			"Couldn't load the repository's README file."
		}
	}

	var body: some View {
		List {
			Section {
				HeaderRepoView(repo)
			}

			if repo.fork == true || repo.template == true || repo.mirror == true || repo.archived == true || repo.originalUrl?.isNotEmpty == true {
				Section {
					VStack(alignment: .leading) {
						if repo.fork == true {
							Label("This repository is a fork of another repository.", systemImage: Icons.forks.rawValue)
						}
						if repo.template == true {
							Label("This repository is a template.", systemImage: "document.on.document")
						}
						if repo.mirror == true {
							Label("This repository is a mirror.", systemImage: "square.stack.3d.forward.dottedline")
							Text("Last updated at \(repo.mirrorUpdated?.toString() ?? ""); Inverval: \(repo.mirrorInterval ?? "")")
								.font(.footnote)
						}
						if repo.archived == true {
							Label("This repository has been archived on \(repo.archivedAt?.toString() ?? "").", systemImage: "archivebox")
						}
						if let originalUrl = repo.originalUrl, let url = URL(string: originalUrl) {
							Link(originalUrl, destination: url)
								.font(.caption)
						}
					}.labelStyle(TrailingIconLabelStyle())
				}.foregroundStyle(.foreground)
			}

			Section {
				if repo.hasIssues == true {
					if let externalTracker = repo.externalTracker?.externalTrackerUrl,
						let url = URL(string: externalTracker)
					{
						Link(
							destination: url,
							label: {
								Label("Issues", systemImage: Icons.issues.rawValue)
							})
					} else {
						NavigationLink(destination: IssueSearchLoader(type: .issues, owner: owner, repo: repoName)) {
							Label(
								title: {
									HStack {
										Text("Issues")
										Spacer()
										Text("\(repo.openIssuesCount ?? 0)")
									}
								},
								icon: {
									Image(systemName: Icons.issues.rawValue)
								})
						}
					}
				}

				if repo.hasPullRequests == true {
					NavigationLink(destination: IssueSearchLoader(type: .pulls, owner: owner, repo: repoName)) {
						Label(
							title: {
								HStack {
									Text("Pull Requests")
									Spacer()
									Text("\(repo.openPrCounter ?? 0)")
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
							UserSearchLoader(context: .repoCollaborators(owner: owner, repo: repoName))
						}
						NavigationLink("Labels") {
							LabelsLoader(owner: owner, repo: repoName)
						}
						NavigationLink("Milestones") {
							MilestonesLoader(owner: owner, repo: repoName)
						}
						NavigationLink("Worktime") {
							RepoWorktimeLoader(owner: owner, repo: repoName)
						}
						// if repo.hasProjects {
						// 	Text("Projects")
						// }
						if repo.hasWiki == true, let externalWiki = repo.externalWiki, let externalWikiUrl = externalWiki.externalWikiUrl, let url = URL(string: externalWikiUrl) {
							Link("Wiki", destination: url)
						}
					},
					label: {
						Label("Plan", systemImage: "calendar.badge.checkmark")
					}
				)

				if repo.hasCode == true {
					DisclosureGroup(
						content: {
							NavigationLink("Code") {
								TreeLoader(owner: owner, repo: repoName, ref: defaultBranch)
							}
							NavigationLink("Commits") {
								CommitsLoader(owner: owner, repo: repoName, ref: defaultBranch)
							}
							NavigationLink("Branches") {
								BranchesLoader(owner: owner, repo: repoName)
							}
							NavigationLink("Tags") {
								TagsLoader(owner: owner, repo: repoName)
							}
						},
						label: {
							Label("Repository", systemImage: Icons.code.rawValue)
						}
					)
				}

				if repo.hasReleases == true || repo.hasActions == true || repo.hasPackages == true {
					DisclosureGroup(
						content: {
							if repo.hasActions == true {
								NavigationLink("Actions") {
									ActionsLoader(owner: owner, repo: repoName)
								}
							}
							if repo.hasReleases == true {
								NavigationLink("Releases") {
									ReleaseLoader(owner: owner, repo: repoName)
								}
							}
							if repo.hasPackages == true {
								NavigationLink("Packages") {
									RepoPackageLoader(owner: owner, repo: repoName)
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
					let readmeBaseURL = Network.baseURL.appending(path: "\(owner)/\(repoName)/src/branch/\(defaultBranch)")
					StructuredText(markdown: readmeContents.emojized(), baseURL: readmeBaseURL)
						.textual.structuredTextStyle(.gitHub)
						.textual.textSelection(.enabled)
				}
			} else if readmeError != nil {
				Section {
					HStack {
						Label("Couldn't load README", systemImage: "exclamationmark.triangle")
							.foregroundStyle(.red)
						Spacer()
						Button("Retry") {
							readmeReload += 1
						}
					}
				}
			}
		}.task(id: readmeReload) {
			await load()
		}.refreshable {
			await load()
		}.toolbar {
			ToolbarItem(placement: .topBarLeading) {
				Menu("More", systemImage: "ellipsis") {
					if let htmlUrl = repo.htmlUrl, let url = URL(string: htmlUrl) {
						Section {
							ShareLink(item: url)
						}
					}

					Section("Clone code") {
						Button("Copy SSH URL") {
							UIPasteboard.general.string = repo.sshUrl ?? ""
							HapticFeedback.notify(.success)
						}
						Button("Copy HTTPS URL") {
							UIPasteboard.general.string = repo.cloneUrl ?? ""
							HapticFeedback.notify(.success)
						}
					}
				}
			}
			ToolbarItem(placement: .topBarTrailing) {
				Menu("Create", systemImage: "plus") {
					if repo.hasIssues == true, repo.externalTracker == nil {
						NavigationLink(destination: NewIssueView(owner: owner, repo: repoName)) {
							Label("New Issue", systemImage: Icons.issues.rawValue)
						}
					}
					if repo.hasPullRequests == true {
						NavigationLink(destination: NewPullRequestView(owner: owner, repo: repoName)) {
							Label("New Pull Request", systemImage: Icons.pull_requests.rawValue)
						}
					}
					NavigationLink(destination: NewLabelView(owner: owner, repo: repoName)) {
						Label("New Label", systemImage: Icons.topics.rawValue)
					}
					NavigationLink(destination: NewMilestoneView(owner: owner, repo: repoName)) {
						Label("New Milestone", systemImage: Icons.milestones.rawValue)
					}
					if repo.hasReleases == true {
						NavigationLink(destination: NewReleaseView(owner: owner, repo: repoName)) {
							Label("New Release", systemImage: "flag")
						}
					}
				}
			}
		}
		.navigationTitle(repo.fullName ?? "")
		.navigationBarTitleDisplayMode(.inline)
	}
}
