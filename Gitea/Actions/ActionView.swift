//
//  ActionView.swift
//  Gitea
//
//  Created by Felix Schindler on 27.05.26.
//

import SwiftUI
import UIKit

struct ActionView: View {
	private let run: Components.Schemas.ActionWorkflowRun
	private let owner: String
	private let repo: String

	@State private var jobsState = LoadState<[Components.Schemas.ActionWorkflowJob]>.loading
	@State private var jobsPaging = Paging()
	@State private var artifactsState = LoadState<[Components.Schemas.ActionArtifact]>.loading
	@State private var downloadingArtifactId: Int64?
	@State private var showDownloadError = false
	@State private var downloadError: Error?

	private let defaultLimit = 7

	init(run: Components.Schemas.ActionWorkflowRun, owner: String, repo: String) {
		self.run = run
		self.owner = owner
		self.repo = repo
	}

	private var status: ActionStatus {
		ActionStatus(conclusion: run.conclusion, status: run.status)
	}

	private var duration: String {
		guard let completedAt = run.completedAt, let startedAt = run.startedAt, completedAt > startedAt else { return "In progress" }
		let interval = completedAt.timeIntervalSince(startedAt)
		guard interval >= 0 else { return "Invalid duration" }
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .abbreviated
		return formatter.string(from: interval) ?? "Unknown"
	}

	private func loadJobs() async {
		guard !jobsPaging.isLoading else { return }
		jobsPaging.reset()
		await loadJobsPage(reset: true)
	}

	private func loadJobsPage(reset: Bool = false) async {
		guard !jobsPaging.isLoading else { return }
		jobsPaging.isLoading = true
		defer { jobsPaging.isLoading = false }
		(jobsState, jobsPaging) = await jobsPaging.nextPage(state: jobsState, limit: defaultLimit, reset: reset) { page in
			try await Network.shared.client.listWorkflowRunJobs(
				path: .init(owner: owner, repo: repo, run: Int(run.id ?? 0)),
				query: .init(page: page, limit: defaultLimit)
			).ok.body.json.jobs ?? []
		}
	}

	private func loadArtifacts() async {
		do {
			artifactsState = .loaded(
				try await Network.shared.client.getArtifactsOfRun(
					path: .init(owner: owner, repo: repo, run: Int(run.id ?? 0))
				).ok.body.json.artifacts ?? [])
		} catch {
			artifactsState = .failed(error)
		}
	}

	private func downloadArtifact(_ artifact: Components.Schemas.ActionArtifact) async throws -> URL {
		guard let urlString = artifact.archiveDownloadUrl, let url = URL(string: urlString) else {
			throw URLError(.badURL)
		}
		return try await Downloader.archive(from: url, fileName: "\(artifact.name ?? "artifact").zip")
	}

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						PillView(status.label, systemImage: status.icon, bgColor: status.color.opacity(0.2), fgColor: status.color)
						Spacer()
						Text("#\(run.runNumber ?? 0)")
							.font(.footnote)
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}

					Text(run.displayTitle ?? "")
						.font(.title3)
						.fontWeight(.medium)

					ScrollView(.horizontal) {
						HStack {
							if let user = run.actor {
								SmallUserView(user, showUsername: true)
							}
							PillView(verbatim: run.event ?? "")
							if let headBranch = run.headBranch {
								PillView(verbatim: headBranch)
							}
							PillView(verbatim: String((run.headSha ?? "").prefix(7)))
								.monospaced()
						}
					}.font(.footnote)

					Divider()

					if let startedAt = run.startedAt {
						LabeledContent("Started", value: startedAt.toString(timeStyle: .short))
					}
					if let completedAt = run.completedAt, let startedAt = run.startedAt, completedAt > startedAt {
						LabeledContent("Completed", value: completedAt.toString(timeStyle: .short))
					}
					LabeledContent("Duration", value: duration)
				}
			}

			Section("Jobs") {
				switch jobsState {
				case .loading:
					LoadingView("Loading jobs", systemImage: Icons.actions.rawValue)
				case .loaded(let jobs), .loadingMore(let jobs), .failedMore(let jobs, _):
					if jobs.isEmpty {
						NoContentView("No jobs", systemImage: Icons.actions.rawValue)
					} else {
						ForEach(jobs, id: \.id) { job in
							ActionsJobView(job: job)
								.onAppear {
									if job.id == jobs.last?.id, jobsPaging.hasMore {
										Task { await loadJobsPage() }
									}
								}
						}
						if case .loadingMore = jobsState {
							LoadingView("Loading more", systemImage: Icons.actions.rawValue)
						} else if case .failedMore(_, let error) = jobsState {
							FailedView(error)
						}
					}
				case .failed(let failure):
					FailedView(failure)
				}
			}

			if case .loaded(let artifacts) = artifactsState {
				Section("Artifacts") {
					if artifacts.isEmpty {
						NoContentView("No artifacts", systemImage: "cube.transparent")
					} else {
						DisclosureGroup("Artifacts (\(artifacts.count))") {
							ForEach(artifacts, id: \.id) { artifact in
								HStack {
									if downloadingArtifactId == artifact.id {
										ProgressView()
											.controlSize(.small)
									} else {
										Image(systemName: "square.and.arrow.down")
									}
									let size = ByteFormatter.shared.format(artifact.sizeInBytes ?? 0)
									Text("\(artifact.name ?? "") (\(size))")
									Spacer()
								}
								.contentShape(Rectangle())
								.onTapGesture {
									guard downloadingArtifactId == nil else { return }
									downloadingArtifactId = artifact.id
									downloadError = nil
									showDownloadError = false
									Task {
										do {
											let url = try await downloadArtifact(artifact)
											Downloader.presentShareSheet(for: url)
										} catch {
											downloadError = error
											showDownloadError = true
										}
										downloadingArtifactId = nil
									}
								}
							}
						}
					}
				}
			} else if case .failed(let error) = artifactsState {
				Section {
					FailedView(error)
				}
			}
		}
		.task {
			async let jobs = loadJobs()
			async let artifacts = loadArtifacts()
			_ = await (jobs, artifacts)
		}
		.alert(
			"Download failed", isPresented: $showDownloadError,
			actions: {
				Button("OK") { downloadError = nil }
			},
			message: {
				Text(downloadError?.localizedDescription ?? "")
			}
		)
		.navigationTitle("Run #\(run.runNumber ?? 0)")
		.navigationBarTitleDisplayMode(.inline)
	}
}
