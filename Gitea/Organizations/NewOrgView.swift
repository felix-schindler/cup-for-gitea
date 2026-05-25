//
//  NewOrgaView.swift
//  Gitea
//
//  Created by Felix Schindler on 10.05.26.
//

import SwiftUI

private func visibilityDisplayName(_ v: Components.Schemas.CreateOrgOption.VisibilityPayload) -> LocalizedStringResource {
	switch v {
	case ._public: "Public"
	case .limited: "Limited"
	case ._private: "Private"
	}
}

struct NewOrgView: View {
	@Environment(\.dismiss) var dismiss

	@State private var name = ""
	@State private var visibility = Components.Schemas.CreateOrgOption.VisibilityPayload._public
	@State private var adminManagesMembers = true

	@State private var error: Error? = nil

	private func save() async {
		do {
			_ = try await Network.shared.client.orgCreate(
				.init(
					body: .json(
						.init(
							//description: <#T##String#>,
							//email: <#T##String#>,
							//fullName: <#T##String#>,
							//location: <#T##String#>,
							repoAdminChangeTeamAccess: adminManagesMembers,
							username: name,
							visibility: visibility
								//website: <#T##String#>
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
					TextField("Organization Name", text: $name)
						.textInputAutocapitalization(.never)
					Text("Organization names should be short and memorable.")
						.font(.footnote)
						.foregroundStyle(.secondary)
				}
				VStack(alignment: .leading) {
					Picker("Visibility", selection: $visibility) {
						ForEach(Components.Schemas.CreateOrgOption.VisibilityPayload.allCases, id: \.self) { v in
							Text(visibilityDisplayName(v)).tag(v)
						}
					}
					if visibility == ._private {
						Text("Visible only to organization members")
							.font(.footnote)
							.foregroundStyle(.secondary)
					} else if visibility == .limited {
						Text("Visible to authenticated users only")
							.font(.footnote)
							.foregroundStyle(.secondary)
					}
				}
				Toggle("Repository admin can add and remove access for teams", isOn: $adminManagesMembers)
			}
		}.toolbar {
			AsyncButton("Save", systemImage: "checkmark") {
				await save()
			}.disabled(name.isEmpty)
			.buttonStyle(.borderedProminent)
		}.scrollDismissesKeyboard(.immediately)
		.navigationTitle("New Organization")
	}
}

#Preview {
	NavigationStack {
		NewOrgView()
	}
}
