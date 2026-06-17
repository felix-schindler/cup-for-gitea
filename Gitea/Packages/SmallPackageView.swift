//
//  SmallPackageView.swift
//  Gitea
//
//  Created by Felix Schindler on 10.06.26.
//

import SwiftUI

struct SmallPackageView: View {
	let pkg: Components.Schemas.Package

	init(_ pkg: Components.Schemas.Package) {
		self.pkg = pkg
	}

	var body: some View {
		VStack(alignment: .leading) {
			ScrollView(.horizontal) {
				HStack {
					SmallUserView(pkg.owner)
					if let repo = pkg.repository {
						NavigationLink(repo.name, destination: FullRepoView(repo))
							.controlSize(.mini)
							.buttonBorderShape(.capsule)
							.adaptiveButtonStyleProminent()
					}
				}
			}.font(.footnote)

			Text(pkg.name)

			ScrollView(.horizontal) {
				HStack {
					Text(pkg._type.capitalized)
					Text(pkg.createdAt.toString(timeStyle: .short))
				}
			}.font(.footnote)
			
			ScrollView(.horizontal) {
				Text(pkg.version)
					.font(.footnote)
					.foregroundStyle(.secondary)
					.monospaced()
			}
		}.swipeActions {
			if let url = URL(string: pkg.htmlUrl) {
				ShareLink(item: url)
			}
		}
	}
}

#Preview {
	let user = Components.Schemas.User(
		active: true, avatarUrl: "https://git.schindlerfelix.de/avatars/2a28dd44a0483741aad7f1611d4269dac57a672427808a1d9f8856247f743ffa", created: Date(), description: "", email: "",
		followersCount: 0, followingCount: 0, fullName: "Felix", htmlUrl: "https://git.schindlerfelix.de/felix-schindler", id: 1, isAdmin: true, language: "", lastLogin: Date(), location: "",
		login: "felix-schindler", loginName: "", prohibitLogin: false, restricted: false, sourceId: 0, starredReposCount: 0, visibility: "", website: "")

	let pkg = Components.Schemas.Package(createdAt: Date(), creator: user, htmlUrl: "https://schindlerfelix.de", id: 2, name: "package-name", owner: user, _type: "container", version: "main")

	NavigationStack {
		List {
			SmallPackageView(pkg)
		}.navigationTitle("Packages")
	}
}
