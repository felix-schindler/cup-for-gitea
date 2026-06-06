import SwiftUI

struct TeamLoader: View {
	let orgName: String

	@State private var state = LoadState<[Components.Schemas.Team]>.loading

	private func load() async {
		state = await LoadState {
			try await Network.shared.client
				.orgListTeams(path: .init(org: orgName))
				.ok.body.json
		}
	}

	var body: some View {
		LoadableList(
			state: state,
			id: \.id,
			loadingText: "Loading Teams",
			emptyText: "This organization has no teams",
			icon: "person.3",
			load: load
		) { team in
			TeamRowView(team: team, orgName: orgName)
		}
		.navigationTitle("Teams")
	}
}

struct TeamRowView: View {
	let team: Components.Schemas.Team
	let orgName: String

	var body: some View {
		Section(team.name) {
			if team.description.isNotEmpty {
				Text(team.description)
					.foregroundStyle(.secondary)
			}

			DisclosureGroup("Permissions") {
				LabeledContent("Level", value: team.permission.rawValue.capitalized)
				if team.canCreateOrgRepo {
					Text("Can create organization repositories")
				}
				if team.includesAllRepositories {
					Text("Has access to all repositories")
				}
				if !team.unitsMap.additionalProperties.isEmpty {
					ForEach(Array(team.unitsMap.additionalProperties.keys.sorted()), id: \.self) { unit in
						LabeledContent(unit, value: team.unitsMap.additionalProperties[unit] ?? "")
					}
				}
			}

			NavigationLink(
				destination: UserSearchLoader(context: .teamMembers(teamId: team.id))
			) {
				Label("Members", systemImage: Icons.users.rawValue)
			}

			NavigationLink(
				destination: RepoSearchLoader(context: .teamRepos(teamId: team.id, org: orgName))
			) {
				Label("Repositories", systemImage: Icons.repositories.rawValue)
			}
		}
	}
}
