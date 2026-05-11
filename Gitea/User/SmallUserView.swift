//
//  TinyUserView.swift
//  Tanuki
//
//  Created by Felix Schindler on 01.03.24.
//

import SwiftUI

struct SmallUserView: View {
	private let user: Components.Schemas.User
	private let showUsername: Bool

	init(_ user: Components.Schemas.User, showUsername: Bool = false) {
		self.user = user
		self.showUsername = showUsername
	}

	public var body: some View {
		NavigationLink(
			destination: NamespaceLoader(user.login),
			label: {
				Label(
					title: {
						if user.fullName.isEmpty {
							Text(user.login)
						} else {
							Text(user.fullName)
						}
					},
					icon: {
						if let url = URL(string: user.avatarUrl) {
							AvatarImage(url, size: .tiny)
						}
					}
				)
			}
		)
		.controlSize(.mini)
		.buttonStyle(.borderedProminent)
		.buttonBorderShape(.capsule)
	}
}

#Preview {
	let user = Components.Schemas.User(
		active: true, avatarUrl: "https://git.schindlerfelix.de/avatars/2a28dd44a0483741aad7f1611d4269dac57a672427808a1d9f8856247f743ffa", created: Date(), description: "", email: "",
		followersCount: 0, followingCount: 0, fullName: "Felix", htmlUrl: "https://git.schindlerfelix.de/felix-schindler", id: 1, isAdmin: true, language: "", lastLogin: Date(), location: "",
		login: "felix-schindler", loginName: "", prohibitLogin: false, restricted: false, sourceId: 0, starredReposCount: 0, visibility: "", website: "")

	VStack {
		SmallUserView(user, showUsername: true)
		SmallUserView(user, showUsername: false)
	}
}
