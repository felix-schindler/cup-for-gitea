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
						if let avatarUrl = org.avatarUrl, let url = URL(string: avatarUrl) {
							AvatarImage(url, size: .medium)
						}
						if org.fullName?.isNotEmpty == true {
							VStack(alignment: .leading) {
								Text(org.fullName ?? "")
								Text(org.name ?? "")
									.font(.footnote)
									.foregroundStyle(.secondary)
							}
						} else {
							Text(org.name ?? "")
						}
						Spacer()
						VisibilityIcon(org.visibility?.value1.rawValue ?? "")
					}

					if org.description?.isNotEmpty == true {
						InlineText(markdown: org.description ?? "")
							.textual.inlineStyle(.gitHub)
							.textual.textSelection(.enabled)
					}

					if let email = org.email, email.isNotEmpty, let url = URL(string: "mailto:\(email)") {
						ScrollView(.horizontal, showsIndicators: false) {
							Link(email, destination: url)
								.tint(.accentColor)
								.buttonStyle(.bordered)
								.controlSize(.mini)
						}
					}

					if org.website?.isNotEmpty == true || org.location?.isNotEmpty == true {
						ScrollView(.horizontal, showsIndicators: false) {
							HStack {
								if let website = org.website, let url = URL(string: website) {
									Link(website, destination: url)
										.tint(.accentColor)
										.buttonStyle(.bordered)
										.controlSize(.mini)
								}
								if org.location?.isNotEmpty == true {
									PillView(verbatim: org.location ?? "", systemImage: "mappin")
								}
							}
						}
					}
				}
			}

			Section {
				NavigationLink(destination: RepoSearchLoader(context: .org(org.id ?? 0))) {
					Label("Repositories", systemImage: Icons.repositories.rawValue)
				}
				// Label("Projects", systemImage: Icons.projects.rawValue)
				NavigationLink(destination: PackageLoader(owner: org.name ?? "")) {
					Label("Packages", systemImage: Icons.packages.rawValue)
				}
				NavigationLink(destination: UserSearchLoader(context: .orgMembers(org: org.name ?? ""))) {
					Label("Members", systemImage: Icons.users.rawValue)
				}
				NavigationLink(destination: TeamLoader(orgName: org.name ?? "")) {
					Label("Teams", systemImage: "person.3")
				}
				NavigationLink(destination: ActivityLoader(context: .org(org.name ?? ""))) {
					Label("Public Activity", systemImage: Icons.activity.rawValue)
				}
			}
		}
		.navigationTitle(org.name ?? "")
		.navigationBarTitleDisplayMode(.inline)
	}
}

#Preview {
	NavigationStack {
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
				visibility: .some(.init(value1: ._private)),
				website: "https://www.schindlerfelix.de/projects/tanuki"
			))
	}
}
