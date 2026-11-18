//
//  PDFPreview.swift
//  Gitea
//
//  Created by Felix Schindler on 18.11.26.
//

import PDFKit
import SwiftUI

struct PDFPreview: UIViewRepresentable {
	private let url: URL

	init(url: URL) {
		self.url = url
	}

	func makeUIView(context: Context) -> PDFView {
		let pdfView = PDFView()
		pdfView.autoScales = true
		pdfView.displayMode = .singlePageContinuous
		pdfView.displayDirection = .vertical
		pdfView.backgroundColor = .clear
		return pdfView
	}

	func updateUIView(_ pdfView: PDFView, context: Context) {
		guard pdfView.document?.documentURL != url else { return }
		pdfView.document = PDFDocument(url: url)
	}
}
