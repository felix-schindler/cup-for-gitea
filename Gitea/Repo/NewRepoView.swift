//
//  NewProject.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

struct NewRepoView: View {
	@Environment(\.dismiss) private var dismiss

	@State private var name = ""
	@State private var makePrivate = true
	@State private var desc = ""
	@State private var initRepo = false
	@State private var makeTemplate = false
	@State private var defaultBranch = "main"
	@State private var objectFormat = Components.Schemas.CreateRepoOption.ObjectFormatNamePayload.sha1
	@State private var gitignore = ""
	@State private var issueLabels = ""
	@State private var license = ""

	@State private var labelTemplates: [String] = []
	@State private var gitignoreTemplates: [String] = []
	@State private var licenseTemplates: [Components.Schemas.LicensesTemplateListEntry] = []

	@State private var error: Error?

	private func load() async {
		if let templates = try? await Network.shared.client.listLabelTemplates().ok.body.json {
			self.labelTemplates = templates
		}

		if let templates = try? await Network.shared.client.listGitignoresTemplates().ok.body.json {
			self.gitignoreTemplates = templates
		}

		if let templates = try? await Network.shared.client.listLicenseTemplates().ok.body.json {
			self.licenseTemplates = templates
		}
	}

	private func create() async {
		do {
			_ = try await Network.shared.client.createCurrentUserRepo(
				.init(
					body: .json(
						.init(
							autoInit: initRepo,
							defaultBranch: defaultBranch,
							description: desc,
							gitignores: gitignore,
							issueLabels: issueLabels,
							license: license,
							name: name,
							objectFormatName: objectFormat,
							_private: makePrivate,
							//readme: <#T##String#>,
							template: makeTemplate,
							//trustModel: <#T##Components.Schemas.CreateRepoOption.TrustModelPayload#>
						)))
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
					TextField("Repository Name", text: $name)
						.textInputAutocapitalization(.never)
					Text(
						"Good repository names use short, memorable and unique keywords. A repository named \".profile\" or \".profile-private\" could be used to add a README.md for the user/organization profile."
					)
					.font(.footnote)
					.foregroundStyle(.secondary)
				}

				VStack(alignment: .leading) {
					Toggle("Make repository private", isOn: $makePrivate)
					Text("Only the owner or the organization members if they have rights, will be able to see it.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				TextField("Description (optional)", text: $desc, axis: .vertical)
					.lineLimit(5)

				if issueLabels.isNotEmpty {
					Picker("Issue-Label-Set", selection: $issueLabels) {
						Text("None").tag("")
						ForEach(labelTemplates, id: \.self) { l in
							Text(l).tag(l)
						}
					}
				}
			}

			Section {
				VStack(alignment: .leading) {
					Toggle("Initialize Repository", isOn: $initRepo)
					Text("Adds .gitignore, License and README")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				// TODO: What to do with readme?
				if initRepo {
					if gitignoreTemplates.isNotEmpty {
						Picker(".gitignore", selection: $gitignore) {
							Text("None").tag("")
							ForEach(gitignoreTemplates, id: \.self) { t in
								Text(t).tag(t)
							}
						}
					}
					if licenseTemplates.isNotEmpty {
						Picker(".gitignore", selection: $license) {
							Text("None").tag("")
							ForEach(licenseTemplates, id: \.self) { l in
								Text(l.name).tag(l.name)
							}
						}
					}
				}
			}

			Section {
				VStack(alignment: .leading) {
					TextField("Default Branch", text: $defaultBranch)
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					Text("The default branch is the base branch for pull requests and code commits.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				VStack(alignment: .leading) {
					Picker("Object Format", selection: $objectFormat) {
						ForEach(Components.Schemas.CreateRepoOption.ObjectFormatNamePayload.allCases, id: \.self) { format in
							Text(format.rawValue.uppercased()).tag(format)
						}
					}
					Text("Object format of the repository. Cannot be changed later. SHA1 is most compatible.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				Toggle("Make repository a template", isOn: $makeTemplate)
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await create()
			}.disabled(name.isEmpty)
			.buttonStyle(.borderedProminent)
		}.task {
			await load()
		}.refreshable {
			await load()
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Repository")
	}
}

#Preview {
	NavigationStack {
		NewRepoView()
	}
}
