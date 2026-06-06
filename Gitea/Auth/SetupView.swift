//
//  SetupView.swift
//  Gitea
//
//  Created by Felix Schindler on 12.05.26.
//

import SwiftUI

struct SetupView: View {
	var body: some View {
		NavigationStack {
			VStack {
				Spacer()

				VStack {
					if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
						let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
						let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
						let lastIcon = iconFiles.last,
						let iconImage = UIImage(named: lastIcon)
					{
						Image(uiImage: iconImage)
							.resizable()
							.scaledToFit()
							.cornerRadius(15)
							.frame(maxWidth: 70, maxHeight: 70)
					}

					Text("Welcome to Cup")
						.font(.title2)
						.fontWeight(.bold)
						.multilineTextAlignment(.center)
				}

				Spacer()

				NavigationLink(
					destination: ConfigView(showSetup: nil),
					label: {
						Text("Configure instance")
							.frame(maxWidth: .infinity)
					}
				)
				.tint(.accentColor)
				.buttonBorderShape(.capsule)
				.buttonStyle(.borderedProminent)
				.controlSize(.large)

				Spacer()
			}
			.padding()
		}
	}
}

#Preview {
	SetupView()
}
