//
//  NewRepoMigrationView.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct NewRepoMigrationView: View {
	@Environment(\.dismiss) private var dismiss

	// Source
	@State private var cloneAddr = ""
	@State private var service: Components.Schemas.MigrateRepoOptions.ServicePayload = .git

	// Auth
	@State private var authUsername = ""
	@State private var authPassword = ""
	@State private var authToken = ""

	// AWS (for CodeCommit)
	@State private var awsAccessKeyId = ""
	@State private var awsSecretAccessKey = ""

	// Target
	@State private var repoName = ""
	@State private var repoOwner = ""
	@State private var description = ""
	@State private var makePrivate = true

	// Mirror
	@State private var mirror = false
	@State private var mirrorInterval = ""

	// Content
	@State private var wiki = true
	@State private var issues = true
	@State private var labels = true
	@State private var milestones = true
	@State private var pullRequests = true
	@State private var releases = true
	@State private var lfs = false
	@State private var lfsEndpoint = ""

	@State private var error: Error?

	private var isAWS: Bool {
		service == .codecommit
	}

	private var supportMetadata: Bool {
		switch service {
		case .git, .codecommit:
			return false
		default:
			return true
		}
	}

	private var contentToggles: [(label: String, binding: Binding<Bool>, supported: Bool)] {
		[
			("Wiki", $wiki, true),
			("Issues", $issues, supportMetadata && !mirror),
			("Labels", $labels, supportMetadata && !mirror),
			("Milestones", $milestones, supportMetadata && !mirror),
			("Pull Requests", $pullRequests, supportMetadata && !mirror),
			("Releases", $releases, supportMetadata && !mirror),
		]
	}

	private func resetContentIfNeeded() {
		if !supportMetadata {
			issues = false
			labels = false
			milestones = false
			pullRequests = false
			releases = false
		}
		if mirror {
			issues = false
			labels = false
			milestones = false
			pullRequests = false
			releases = false
		}
	}

	private func create() async {
		resetContentIfNeeded()
		do {
			_ = try await Network.shared.client.repoMigrate(
				body: .json(
					.init(
						authPassword: authPassword,
						authToken: authToken,
						authUsername: authUsername,
						awsAccessKeyId: isAWS ? awsAccessKeyId : "",
						awsSecretAccessKey: isAWS ? awsSecretAccessKey : "",
						cloneAddr: cloneAddr,
						description: description,
						issues: issues,
						labels: labels,
						lfs: lfs,
						lfsEndpoint: lfs ? lfsEndpoint : "",
						milestones: milestones,
						mirror: mirror,
						mirrorInterval: mirror ? mirrorInterval : "",
						_private: makePrivate,
						pullRequests: pullRequests,
						releases: releases,
						repoName: repoName,
						repoOwner: repoOwner,
						service: service,
						uid: 0,
						wiki: wiki
					))
			).created

			HapticFeedback.notify(.success)
			dismiss()
		} catch {
			self.error = error
			HapticFeedback.notify(.error)
		}
	}

	var body: some View {
		Form {
			if let error {
				Section {
					FailedView(error)
				}
			}

			Section {
				VStack(alignment: .leading) {
					TextField("Clone URL", text: $cloneAddr)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Text("The URL of the remote git repository to migrate.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				Picker("Service", selection: $service) {
					ForEach(Components.Schemas.MigrateRepoOptions.ServicePayload.allCases, id: \.self) { s in
						Text(s.rawValue.capitalized).tag(s)
					}
				}
			}

			Section {
				TextField("Username", text: $authUsername)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
				SecureField("Password", text: $authPassword)
				SecureField("Token", text: $authToken)
			} header: {
				Text("Authentication")
			}

			if isAWS {
				Section {
					TextField("Access Key ID", text: $awsAccessKeyId)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					SecureField("Secret Access Key", text: $awsSecretAccessKey)
				} header: {
					Text("AWS CodeCommit")
				}
			}

			Section {
				VStack(alignment: .leading) {
					TextField("Repository Name", text: $repoName)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Text("Name for the migrated repository.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				TextField("Owner (optional)", text: $repoOwner)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()

				TextField("Description (optional)", text: $description, axis: .vertical)
					.lineLimit(5)

				VStack(alignment: .leading) {
					Toggle("Make repository private", isOn: $makePrivate)
					Text("Only the owner or organization members will be able to see it.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			} header: {
				Text("Target")
			}

			Section {
				VStack(alignment: .leading) {
					Toggle("Mirror", isOn: $mirror)
					Text("The repository will be kept in sync with the remote.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				if mirror {
					VStack(alignment: .leading) {
						TextField("Mirror Interval", text: $mirrorInterval)
							.textInputAutocapitalization(.never)
							.autocorrectionDisabled()
						Text("e.g. 8h, 1d, 30m")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
			}

			Section {
				ForEach(contentToggles, id: \.label) { item in
					Toggle(item.label, isOn: item.binding)
						.disabled(!item.supported)
				}
				Toggle("LFS", isOn: $lfs)
				if lfs {
					TextField("LFS Endpoint (optional)", text: $lfsEndpoint)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
				}
				if !supportMetadata {
					Text("Only Git data and wiki can be migrated from this service type.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				} else if mirror {
					Text("Mirrors only support Git data and wiki.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
			} header: {
				Text("Migration Content")
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(cloneAddr.isEmpty || repoName.isEmpty)
			.buttonStyle(.borderedProminent)
		}
		.onChange(of: service) { _, _ in
			resetContentIfNeeded()
		}
		.onChange(of: mirror) { _, _ in
			resetContentIfNeeded()
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Migration")
	}
}

#Preview {
	NavigationStack {
		NewRepoMigrationView()
	}
}
