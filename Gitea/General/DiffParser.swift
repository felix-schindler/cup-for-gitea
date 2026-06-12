import Foundation

enum DiffLineType {
	case addition
	case deletion
	case context
	case hunkHeader
	case fileHeader
}

struct DiffLine: Identifiable, Equatable {
	let id = UUID()
	let content: String
	let type: DiffLineType
	let oldLineNumber: Int?
	let newLineNumber: Int?

	static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
		lhs.id == rhs.id
	}
}

struct FileDiff: Identifiable {
	let id = UUID()
	let fileName: String
	let status: String
	let lines: [DiffLine]
}

enum DiffParser {
	static func parse(_ text: String) -> [FileDiff] {
		let lines = text.components(separatedBy: "\n")
		var files: [FileDiff] = []
		var currentFileLines: [DiffLine] = []
		var currentFileName = ""
		var currentStatus = "modified"
		var inDiff = false

		for line in lines {
			if line.hasPrefix("diff --git ") {
				if inDiff, !currentFileLines.isEmpty {
					files.append(
						FileDiff(
							fileName: currentFileName,
							status: currentStatus,
							lines: currentFileLines
						))
				}
				currentFileLines = []
				currentFileName = extractFileName(from: line)
				currentStatus = "modified"
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
				inDiff = true
			} else if line.hasPrefix("new file mode") {
				currentStatus = "added"
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("deleted file mode") {
				currentStatus = "deleted"
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("rename from") || line.hasPrefix("rename to") {
				currentStatus = "renamed"
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("similarity index") {
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("index ") {
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("--- ") || line.hasPrefix("+++ ") {
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("@@") {
				let (oldLine, newLine) = parseHunkHeader(line)
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .hunkHeader,
						oldLineNumber: oldLine,
						newLineNumber: newLine
					))
			} else if line.hasPrefix("+") {
				currentFileLines.append(
					DiffLine(
						content: String(line.dropFirst()),
						type: .addition,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("-") {
				currentFileLines.append(
					DiffLine(
						content: String(line.dropFirst()),
						type: .deletion,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix(" ") {
				currentFileLines.append(
					DiffLine(
						content: String(line.dropFirst()),
						type: .context,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if line.hasPrefix("Binary files") {
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .fileHeader,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			} else if !inDiff {
				continue
			} else {
				currentFileLines.append(
					DiffLine(
						content: line,
						type: .context,
						oldLineNumber: nil,
						newLineNumber: nil
					))
			}
		}

		if inDiff, !currentFileLines.isEmpty {
			files.append(
				FileDiff(
					fileName: currentFileName,
					status: currentStatus,
					lines: currentFileLines
				))
		}

		return files
	}

	private static func extractFileName(from line: String) -> String {
		let prefix = " b/"
		guard let range = line.range(of: prefix) else { return line }
		var name = String(line[range.upperBound...])
		if name.hasPrefix("\"") {
			name = String(name.dropFirst().dropLast())
		}
		return name
	}

	private static func parseHunkHeader(_ line: String) -> (Int?, Int?) {
		let pattern = /@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/
		guard let match = try? pattern.firstMatch(in: line) else {
			return (nil, nil)
		}
		return (Int(match.1), Int(match.2))
	}
}
