//
//  InstancesView.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI

struct InstancesView: View {
	@State private var instances: [GiteaInstance] = InstanceManager.instances
	@State private var selectedId: String? = InstanceManager.selectedId
	@State private var error: Error?
	@State private var switchingId: String?

	@ViewBuilder
	private func statusView(for instance: GiteaInstance) -> some View {
		if switchingId == instance.id {
			ProgressView()
		} else if instance.id == selectedId {
			Image(systemName: "checkmark.circle.fill")
				.foregroundStyle(.accent)
		}
	}

	@MainActor
	private func handleRemovalSwitch() async {
		let next = InstanceManager.selected
		if let next {
			do {
				switchingId = next.id
				self.error = nil
				try await Auth.switchInstance(to: next)
				HapticFeedback.notify(.success)
			} catch {
				self.error = error
				HapticFeedback.notify(.error)
			}
			switchingId = nil
		} else {
			Auth.logout()
		}
	}

	var body: some View {
		List {
			if let error {
				Section {
					FailedView(error)
				}
			}

			if instances.isEmpty {
				NoContentView(
					"No Instances",
					systemImage: "server.rack",
					description: "Add a Gitea instance to get started"
				)
			} else {
				ForEach(instances) { instance in
					HStack {
						Text(instance.baseURL.absoluteString)

						Spacer()
						statusView(for: instance)
					}
					.contentShape(.rect)
					.onTapGesture {
						if switchingId != nil {
							return
						}
						Task {
							do {
								switchingId = instance.id
								self.error = nil
								try await Auth.switchInstance(to: instance)
								instances = InstanceManager.instances
								selectedId = InstanceManager.selectedId
								HapticFeedback.notify(.success)
							} catch {
								self.error = error
								HapticFeedback.notify(.error)
							}
							switchingId = nil
						}
					}
					.swipeActions(edge: .trailing) {
						Button(role: .destructive) {
							let wasSelected = instance.id == InstanceManager.selectedId
							InstanceManager.remove(instance)
							instances = InstanceManager.instances
							selectedId = InstanceManager.selectedId
							if wasSelected {
								Task {
									await handleRemovalSwitch()
								}
							}
						} label: {
							Label("Delete", systemImage: "trash").labelStyle(.iconOnly)
						}
					}
				}
			}
		}.task {
			instances = InstanceManager.instances
			selectedId = InstanceManager.selectedId
		}.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				NavigationLink(destination: ConfigView(showSetup: nil)) {
					Label("Add Instance", systemImage: "plus")
						.labelStyle(.titleAndIcon)
						.tint(.accentColor)
				}
			}
		}.navigationTitle("Instances")
	}
}

#Preview {
	NavigationStack {
		InstancesView()
	}
}
