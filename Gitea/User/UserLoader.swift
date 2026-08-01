//
//  ProfileView.swift
//  cup-gitea
//
//  Created by Felix Schindler on 09.05.26.
//

import SwiftUI
import Textual

struct UserLoader: View {
	private let username: String?
	private let isNamespace: Bool

	@State private var user: Result<Components.Schemas.User, Error>?

	init(username: String? = nil, isNamespace: Bool = false) {
		self.username = username
		self.isNamespace = isNamespace
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
								if let avatarUrl = u.avatarUrl, let url = URL(string: avatarUrl) {
									AvatarImage(url, size: .medium)
								}

								VStack(alignment: .leading) {
									HStack {
										if u.fullName?.isNotEmpty == true {
											Text(u.fullName ?? "")
										} else {
											Text(u.login ?? "")
										}

										if u.isAdmin == true {
											Image(systemName: "checkmark.seal")
										}

										VisibilityIcon(u.visibility?.value1.rawValue ?? "")
									}

									if u.fullName?.isNotEmpty == true {
										Text("@\(u.login ?? "")")
											.font(.footnote)
											.foregroundStyle(.secondary)
									}
								}.labelStyle(TrailingIconLabelStyle(useSpacer: false))

								Spacer()

								VStack(alignment: .trailing) {
									Text(u.created?.toString() ?? "")
									Text("#\(u.id ?? 0)")
								}.font(.footnote)
							}

							ScrollView(.horizontal, showsIndicators: false) {
								HStack {
									if let email = u.email, email.isNotEmpty, let url = URL(string: "mailto:\(email)") {
										Link(email, destination: url)
											.tint(.accentColor)
											.buttonStyle(.bordered)
											.controlSize(.mini)
									}

									if let website = u.website, let url = URL(string: website) {
										Link(website, destination: url)
											.tint(.accentColor)
											.buttonStyle(.bordered)
											.controlSize(.mini)
									}

									if u.location?.isNotEmpty == true {
										PillView(verbatim: u.location ?? "", systemImage: "mappin")
									}
								}.font(.footnote)
							}

							ScrollView(.horizontal, showsIndicators: false) {
								HStack {
									NavigationLink("\(u.followersCount ?? 0) Followers", destination: FollowLoader(u.login ?? "", type: .followers))
									NavigationLink("\(u.followingCount ?? 0) Following", destination: FollowLoader(u.login ?? "", type: .following))
								}
								.controlSize(.mini)
								.buttonBorderShape(.capsule)
								.adaptiveButtonStyle()
								.font(.footnote)
							}

							if u.description?.isNotEmpty == true {
								InlineText(markdown: (u.description ?? "").emojized())
									.textual.inlineStyle(.gitHub)
									.textual.textSelection(.enabled)
							}
						}

						// TODO: Maybe display active, restricted or prohibit_login?
					}

					Section {
						NavigationLink(
							destination: RepoSearchLoader(context: .user(u.id ?? 0)),
							label: {
								Label("Repositories", systemImage: Icons.repositories.rawValue)
							})

						NavigationLink(destination: UserOrgLoader()) {
							Label("Organizations", systemImage: Icons.organizations.rawValue)
						}

						// Label("Projects", systemImage: Icons.projects.rawValue)
						NavigationLink(destination: PackageLoader(owner: u.login ?? "")) {
							Label("Packages", systemImage: Icons.packages.rawValue)
						}
						NavigationLink(destination: ActivityLoader(context: .user(u.login ?? ""))) {
							Label("Public Activity", systemImage: Icons.activity.rawValue)
						}

						NavigationLink(
							destination: RepoSearchLoader(context: .search, starredBy: u.id),
							label: {
								Label(
									title: {
										HStack {
											Text("Starred Repositories")
											Spacer()
											Text(String(u.starredReposCount ?? 0))
										}
									},
									icon: {
										Image(systemName: Icons.starred.rawValue)
									})
							})
					}
				case .failure(let failure):
					if isNamespace {
						FailedView(failure)
					} else {
						FailedView(failure)
					}
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
				if let user, case .success(let u) = user, let htmlUrl = u.htmlUrl, let url = URL(string: htmlUrl) {
					ShareLink(item: url)
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
			.navigationBarTitleDisplayMode(.inline)
	}
}

#Preview {
	NavigationStack {
		UserLoader(username: "felix-schindler")
	}
}
