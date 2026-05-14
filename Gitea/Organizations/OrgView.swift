//
//  OrgLoader.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI
import Textual

struct OrgView: View {
	let org: Components.Schemas.Organization

	var body: some View {
		List {
			Section {
				VStack(alignment: .leading) {
					HStack {
						if let url = URL(string: org.avatarUrl) {
							AvatarImage(url, size: .medium)
						}
						if org.fullName.isNotEmpty {
							VStack(alignment: .leading) {
								Text(org.fullName)
								Text(org.name)
									.font(.footnote)
									.foregroundStyle(.secondary)
							}
						} else {
							Text(org.name)
						}
						Spacer()
						VisibilityIcon(org.visibility)
					}

					if org.description.isNotEmpty {
						InlineText(markdown: org.description)
							.textual.inlineStyle(.gitHub)
							.textual.textSelection(.enabled)
					}

					if org.email.isNotEmpty {
						ScrollView(.horizontal, showsIndicators: false) {
							Link(org.email, destination: URL(string: "mailto:\(org.email)")!)
								.tint(.accentColor)
								.buttonStyle(.bordered)
								.controlSize(.mini)
						}
					}

					if org.website.isNotEmpty || org.location.isNotEmpty {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack {
								if let url = URL(string: org.website) {
									Link(org.website, destination: url)
										.tint(.accentColor)
										.buttonStyle(.bordered)
										.controlSize(.mini)
								}
								if org.location.isNotEmpty {
									PillView(org.location, systemImage: "mappin")
								}
							}
						}
					}
				}
			}

			Section {
				NavigationLink(destination: OrgReposLoader(org.name)) {
					Label("Repositories", systemImage: Icons.repositories.rawValue)
				}
				// Label("Projects", systemImage: Icons.projects.rawValue)
				// Label("Packages", systemImage: Icons.packages.rawValue)
				NavigationLink(destination: OrgMembersLoader(org.name)) {
					Label("Members", systemImage: Icons.users.rawValue)
				}
				// Label("Teams", systemImage: "person.2")
				// Label("Worktime", systemImage: "clock")
			}
		}
	}
}

#Preview {
	OrgView(
		org: .init(
			avatarUrl: "https://git.schindlerfelix.de/avatars/2a28dd44a0483741aad7f1611d4269dac57a672427808a1d9f8856247f743ffa",
			description: "Mobile App for GitLab",
			email: "",
			fullName: "",
			id: 5,
			location: "",
			name: "Tanuki",
			repoAdminChangeTeamAccess: true,
			username: "Tanuki",
			visibility: "private",
			website: "https://www.schindlerfelix.de/projects/tanuki"
		))
}
