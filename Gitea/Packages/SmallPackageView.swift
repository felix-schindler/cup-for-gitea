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
		Link(destination: URL(string: pkg.htmlUrl)!) {
			Label(
				title: {
					Text(pkg.name)
					ScrollView(.horizontal) {
						if let name = pkg.repository?.fullName, name.isNotEmpty {
							Text("\(pkg._type) · \(pkg.version) · \(name)")
						} else {
							Text("\(pkg._type) · \(pkg.version)")
						}
					}.font(.footnote)
				},
				icon: {
					Image(systemName: Icons.packages.rawValue)
						.foregroundStyle(.accent)
				})
		}
	}
}
