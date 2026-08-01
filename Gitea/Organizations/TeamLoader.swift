import SwiftUI

struct TeamLoader: View {
	let orgName: String

	@State private var state = LoadState<[Components.Schemas.Team]>.loading

	private func load() async {
		do {
			state = .loaded(
				try await Network.shared.client
					.orgListTeams(path: .init(org: orgName))
					.ok.body.json)
		} catch {
			state = .failed(error)
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
		Section(team.name ?? "") {
			if team.description?.isNotEmpty == true {
				Text(team.description ?? "")
					.foregroundStyle(.secondary)
			}

			DisclosureGroup("Permissions") {
				LabeledContent("Level", value: team.permission?.rawValue.capitalized ?? "")
				if team.canCreateOrgRepo == true {
					Text("Can create organization repositories")
				}
				if team.includesAllRepositories == true {
					Text("Has access to all repositories")
				}
				if let unitsMap = team.unitsMap, !unitsMap.additionalProperties.isEmpty {
					ForEach(Array(unitsMap.additionalProperties.keys.sorted()), id: \.self) { unit in
						LabeledContent(unit, value: unitsMap.additionalProperties[unit] ?? "")
					}
				}
			}

			NavigationLink(
				destination: UserSearchLoader(context: .teamMembers(teamId: team.id ?? 0))
			) {
				Label("Members", systemImage: Icons.users.rawValue)
			}

			NavigationLink(
				destination: RepoSearchLoader(context: .teamRepos(teamId: team.id ?? 0, org: orgName))
			) {
				Label("Repositories", systemImage: Icons.repositories.rawValue)
			}
		}
	}
}
