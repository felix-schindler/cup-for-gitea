//
//  SmallOrgView.swift
//  Gitea
//
//  Created by Felix Schindler on 11.05.26.
//

import SwiftUI

struct SmallOrgView: View {
	let org: Components.Schemas.Organization

	init(_ org: Components.Schemas.Organization) {
		self.org = org
	}

	var body: some View {
		NavigationLink(destination: OrgView(org: org)) {
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
		}
	}
}

#Preview {
	List {
		SmallOrgView(
			.init(
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
}
