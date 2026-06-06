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
	@State private var artifactsState = LoadState<[Components.Schemas.ActionArtifact]>.loading
	@State private var downloadingArtifactId: Int64?
	@State private var showDownloadError = false
	@State private var downloadError: Error?

	init(run: Components.Schemas.ActionWorkflowRun, owner: String, repo: String) {
		self.run = run
		self.owner = owner
		self.repo = repo
	}

	private var status: ActionStatus {
		ActionStatus(conclusion: run.conclusion ?? "", status: run.status)
	}

	private var duration: String {
		guard run.completedAt > run.startedAt else { return "In progress" }
		let interval = run.completedAt.timeIntervalSince(run.startedAt)
		guard interval >= 0 else { return "Invalid duration" }
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .abbreviated
		return formatter.string(from: interval) ?? "Unknown"
	}

	private func loadJobs() async {
		jobsState = await LoadState {
			try await Network.shared.client.listWorkflowRunJobs(
				path: .init(owner: owner, repo: repo, run: Int(run.id)),
				query: .init(page: 1, limit: 50)
			).ok.body.json.jobs
		}
	}

	private func loadArtifacts() async {
		artifactsState = await LoadState {
			try await Network.shared.client.getArtifactsOfRun(
				path: .init(owner: owner, repo: repo, run: Int(run.id))
			).ok.body.json.artifacts
		}
	}

	private func downloadArtifact(_ artifact: Components.Schemas.ActionArtifact) async throws -> URL {
		guard let url = URL(string: artifact.archiveDownloadUrl) else {
			throw URLError(.badURL)
		}
		var request = URLRequest(url: url)
		request.setValue("token \(Network.shared.token)", forHTTPHeaderField: "Authorization")
		let (data, _) = try await URLSession.shared.data(for: request)
		let tempURL = FileManager.default.temporaryDirectory
			.appendingPathComponent(artifact.name)
			.appendingPathExtension("zip")
		try data.write(to: tempURL)
		return tempURL
	}

	@MainActor
	private func presentShareSheet(for url: URL) {
		guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
			  let root = windowScene.windows.first?.rootViewController else { return }
		let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
		root.present(vc, animated: true)
	}

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading, spacing: 12) {
					HStack {
						PillView(status.label, systemImage: status.icon, bgColor: status.color.opacity(0.2), fgColor: status.color)
						Spacer()
						Text("#\(run.runNumber)")
							.font(.footnote)
							.foregroundStyle(.secondary)
							.monospacedDigit()
					}

					Text(run.displayTitle)
						.font(.title3)
						.fontWeight(.medium)

					ScrollView(.horizontal) {
						HStack {
							if let user = run.actor {
								SmallUserView(user, showUsername: true)
							}
							PillView(verbatim: run.event)
							if let headBranch = run.headBranch {
								PillView(verbatim: headBranch)
							}
							PillView(verbatim: String(run.headSha.prefix(7)))
								.monospaced()
						}
					}.font(.footnote)

					Divider()

					LabeledContent("Started", value: run.startedAt.toString(timeStyle: .short))
					if run.completedAt > run.startedAt {
						LabeledContent("Completed", value: run.completedAt.toString(timeStyle: .short))
					}
					LabeledContent("Duration", value: duration)
				}
			}

			Section("Jobs") {
				switch jobsState {
				case .loading:
					LoadingView("Loading jobs", systemImage: Icons.actions.rawValue)
				case .loaded(let jobs):
					if jobs.isEmpty {
						NoContentView("No jobs", systemImage: Icons.actions.rawValue)
					} else {
						ForEach(jobs, id: \.id) { job in
							ActionsJobView(job: job)
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
									Text("\(artifact.name) (\(ByteFormatter.shared.format(artifact.sizeInBytes)))")
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
											presentShareSheet(for: url)
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
		.alert("Download failed", isPresented: $showDownloadError, actions: {
			Button("OK") { downloadError = nil }
		}, message: {
			Text(downloadError?.localizedDescription ?? "")
		})
		.navigationTitle("Run #\(run.runNumber)")
		.navigationBarTitleDisplayMode(.inline)
	}
}
