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

	@State private var error: Error?

	private func create() async {
		do {
			_ = try await Network.shared.client.createCurrentUserRepo(
				.init(
					body: .json(
						.init(
							autoInit: initRepo,
							defaultBranch: defaultBranch,
							description: desc,
							//gitignores: <#T##String#>,
							//issueLabels: <#T##String#>,
							//license: <#T##String#>,
							name: name,
							objectFormatName: objectFormat,
							_private: makePrivate,
							//readme: <#T##String#>,
							//template: <#T##Bool#>,
							//trustModel: <#T##Components.Schemas.CreateRepoOption.TrustModelPayload#>
						)))
			).created

			HapticFeedback.notify(.success)
			dismiss()
		} catch {
			self.error = error
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
					Text(
						"Good repository names use short, memorable and unique keywords. A repository named \".profile\" or \".profile-private\" could be used to add a README.md for the user/organization profile."
					)
					.font(.footnote)
					.foregroundStyle(.secondary)
				}

				VStack(alignment: .leading) {
					Toggle("Visibility", isOn: $makePrivate)
					Text("Only the owner or the organization members if they have rights, will be able to see it.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}

				TextField("Description", text: $desc, axis: .vertical)
					.lineLimit(5)
			}

			// TODO: Let the user choose template repo
			// TODO: when not from template: Issue label set
			// TODO: when not from template: Init with .gitignore, license, readme

			/* Section {
				VStack(alignment: .leading) {
					Toggle("Initialize Repository", isOn: $initRepo)
					Text("Adds .gitignore, License and README")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				if (initRepo) {
				}
			} */

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
			}.buttonStyle(.borderedProminent)
		}.navigationTitle("New Repository")
	}
}

#Preview {
	NavigationStack {
		NewRepoView()
	}
}
