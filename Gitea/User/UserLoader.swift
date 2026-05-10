//
//  ProfileView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI
import Textual

struct UserVisibilityIcon: View {
	private let systemName: String

	init(_ visibility: String) {
		self.systemName =
			switch visibility {
			case "private":
				"lock"
			case "limited":
				"network.badge.shield.half.filled"
			default:
				"network"
			}
	}

	var body: some View {
		Image(systemName: systemName)
	}
}

struct UserLoader: View {
	private let username: String?

	@State private var user: Result<Components.Schemas.User, Error>?

	init(username: String? = nil) {
		self.username = username
	}

	private func load() async {
		do {
			var user: Components.Schemas.User
			if let username {
				user = try await Network.shared.client.userGet(.init(path: .init(username: username))).ok.body.json
			} else {
				user = try await Network.shared.client.userGetCurrent().ok.body.json
			}
			self.user = .success(user)
		} catch {
			self.user = .failure(error)
		}
	}

	var body: some View {
		List {
			if let user {
				switch user {
				case .success(let u):
					Section {
						VStack(alignment: .leading) {
							HStack {
								if let url = URL(string: u.avatarUrl) {
									AvatarImage(url, size: .medium)
								}

								VStack(alignment: .leading) {
									HStack {
										if u.fullName.isNotEmpty {
											Text(u.fullName)
										} else {
											Text(u.login)
										}

										if u.isAdmin {
											Image(systemName: "checkmark.seal")
										}

										UserVisibilityIcon(u.visibility)
									}

									if u.fullName.isNotEmpty {
										Text("@\(u.login)")
											.font(.footnote)
											.foregroundStyle(.secondary)
									}
								}.labelStyle(TrailingIconLabelStyle(useSpacer: false))

								Spacer()

								VStack(alignment: .trailing) {
									Text(u.created.toString())
									Text("#\(u.id)")
								}.font(.footnote)
							}

							ScrollView(.horizontal, showsIndicators: false) {
								HStack {
									if u.email.isNotEmpty, let url = URL(string: "mailto:\(u.email)") {
										Link(u.email, destination: url)
											.tint(.accentColor)
											.buttonStyle(.bordered)
											.controlSize(.mini)
									}

									if let url = URL(string: u.website) {
										Link(u.website, destination: url)
											.tint(.accentColor)
											.buttonStyle(.bordered)
											.controlSize(.mini)
									}

									if u.location.isNotEmpty {
										PillView(u.location, systemImage: "mappin")
									}
								}.font(.footnote)
							}

							ScrollView(.horizontal, showsIndicators: false) {
								HStack {
									NavigationLink(destination: FollowLoader(u.login, type: .followers)) {
										PillView("\(u.followersCount) Followers")
									}
									NavigationLink(destination: FollowLoader(u.login, type: .following)) {
										PillView("\(u.followingCount) Following")
									}
								}.font(.footnote)
							}

							if u.description.isNotEmpty {
								InlineText(markdown: u.description.emojized())
									.textual.inlineStyle(.gitHub)
									.textual.textSelection(.enabled)
							}
						}

						// TODO: Maybe display active, restricted or prohibit_login?
					}

					Section {
						NavigationLink(destination: UserReposLoader(username), label: {
							Label("Repositories", systemImage: Icons.repositories.rawValue)
						})
						Label("Projects", systemImage: Icons.projects.rawValue)
						Label("Packages", systemImage: Icons.packages.rawValue)
						Label("Public Activity", systemImage: Icons.activity.rawValue)

						NavigationLink(destination: StarredReposLoader(username), label: {
							Label(
								title: {
									HStack {
										Text("Starred Repositories")
										Spacer()
										Text(String(u.starredReposCount))
									}
								},
								icon: {
									Image(systemName: Icons.starred.rawValue)
								})
						})
					}
				case .failure(let failure):
					FailedView(failure)
				}
			} else {
				LoadingView("Loading user", systemImage: Icons.users.rawValue)
			}
		}.task {
			await load()
		}.refreshable {
			await load()
		}.toolbar {
			HStack {
				if let user, case .success(let u) = user, let url = URL(string: u.htmlUrl) {
					ShareLink(
						item: url,
						label: {
							Label("Share", systemImage: Icons.share.rawValue)
						})
				}
				if username == nil {
					NavigationLink(
						destination: SettingsView(),
						label: {
							Label("Settings", systemImage: Icons.settings.rawValue)
						})
				}
			}
		}.navigationTitle(username ?? "Profile")
	}
}

#Preview {
	NavigationStack {
		UserLoader(username: "felix-schindler")
	}
}
