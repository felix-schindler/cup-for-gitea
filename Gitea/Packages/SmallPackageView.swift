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
			Label(title: {
				Text(pkg.name)
				ScrollView(.horizontal) {
					Text("\(pkg._type) · \(pkg.version) · \(pkg.repository.fullName)")
				}.font(.footnote)
			}, icon: {
				Image(systemName: Icons.packages.rawValue)
					.foregroundStyle(.accent)
			})
		}
	}
}
