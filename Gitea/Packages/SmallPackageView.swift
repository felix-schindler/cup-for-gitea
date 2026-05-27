//
//  SmallPackageView.swift
//  Gitea
//
//  Created by Felix Schindler on 28.05.26.
//

import SwiftUI

struct SmallPackageView: View {
	private let pkg: Components.Schemas.Package

	init(_ pkg: Components.Schemas.Package) {
		self.pkg = pkg
	}

	var body: some View {
		HStack {
			Image(systemName: Icons.packages.rawValue)
				.foregroundStyle(.accent)
				.frame(width: 24)
			VStack(alignment: .leading) {
				Text(pkg.name)
					.font(.body)
				Text("\(pkg._type) · \(pkg.version)")
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
	}
}
