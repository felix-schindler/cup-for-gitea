//
//  ConfigView.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI

struct ConfigView: View {
	@Environment(\.dismiss) var dismiss

	public private(set) var showSetup: Binding<Bool>? = nil

	@State private var newHost = "gitea.com"
	@State private var newToken = ""
	@State private var errorMessage: LocalizedStringKey?

	private func sanitizeHost(_ input: String) -> String {
		let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
		if trimmed.contains("/") {
			if let tempUrl = URL(string: trimmed), let host = tempUrl.host {
				return host
			}
		}
		return trimmed
	}

	var body: some View {
		Form {
			Section {
				Label("Gitea URL", systemImage: "link")
					.font(.headline)
				TextField("gitea.example.com", text: $newHost)
					.keyboardType(.URL)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()

				Label("Access Token", systemImage: "key")
					.font(.headline)
				TextField("77eabb36d04f1c5c32cd609b8b44c6b3", text: $newToken)
					.textInputAutocapitalization(.never)
					.autocorrectionDisabled()
			}

			Section {
				VStack(alignment: .leading) {
					Label("Scopes", systemImage: "checkmark.circle.fill")
						.font(.headline)
					VStack(alignment: .leading) {
						Label("`activitypub: No Access`", systemImage: "checkmark.circle")
						Label("`issue: read and write`", systemImage: "checkmark.circle")
						Label("`misc: read`", systemImage: "checkmark.circle")
						Label("`notification: read and write`", systemImage: "checkmark.circle")
						Label("`organization: read and write`", systemImage: "checkmark.circle")
						Label("`package: read`", systemImage: "checkmark.circle")
						Label("`repository: read and write`", systemImage: "checkmark.circle")
						Label("`user: read and write`", systemImage: "checkmark.circle")
					}.font(.footnote)
				}
			}

			if let errorMessage {
				Section {
					Text(errorMessage)
						.foregroundStyle(.red)
						.font(.footnote)
						.multilineTextAlignment(.center)
				}
			}

			Section {
				AsyncButton(
					action: {
						errorMessage = nil
						let host = sanitizeHost(newHost)
						guard host.isNotEmpty else {
							errorMessage = "Please provide a valid host"
							return
						}
						guard newToken.isNotEmpty else {
							errorMessage = "Please provide a valid token"
							return
						}

						do {
							let instance = GiteaInstance(host: host, token: newToken)
							try await Auth.login(
								instance: instance,
								showSetup: showSetup,
								dismiss: dismiss
							)
						} catch {
							errorMessage = "Failed to log in: \(error.localizedDescription)"
						}
					},
					label: {
						Label("Save config", systemImage: "checkmark")
							.frame(maxWidth: .infinity)
					}
				)
				.buttonBorderShape(.capsule)
				.buttonStyle(.borderedProminent)
				.controlSize(.large)
			}
		}
		.scrollDismissesKeyboard(.immediately)
		.navigationTitle("Configure instance")
	}
}

#Preview {
	NavigationStack {
		ConfigView(showSetup: .constant(true))
	}
}
