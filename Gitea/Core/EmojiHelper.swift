//
//  EmojiCodes.swift
//  GitLab
//
//  Created by Felix Schindler on 02.11.21.
//

import Foundation

class EmojiHelper {
	private static let emojiCodes: [String: String] = {
		guard let url = Bundle.main.url(forResource: "emoji", withExtension: "json"),
			let data = try? Data(contentsOf: url),
			let codes = try? JSONDecoder().decode([String: String].self, from: data)
		else {
			print("WARNING: Failed to load emoji.json")
			return [:]
		}
		return codes
	}()

	private static let emojiRegex = try? NSRegularExpression(
		pattern: "(:[a-z0-9-+_]+:)", options: .caseInsensitive)

	public static func emojizedStringWithString(text: String) -> String {
		guard let regex = emojiRegex else { return text }
		var resultText = text
		let matchingRange = NSMakeRange(0, resultText.utf16.count)
		regex.enumerateMatches(
			in: resultText, options: .reportCompletion,
			range: matchingRange,
			using: {
				(
					result: NSTextCheckingResult?,
					flags: NSRegularExpression.MatchingFlags,
					stop: UnsafeMutablePointer<ObjCBool>
				) -> Void in
				if let result, result.resultType == .regularExpression {
					let range = result.range
					if range.location != NSNotFound {
						let code = (text as NSString).substring(with: range)
						let unicode = EmojiHelper.emojiAliases(key: code)
						if unicode.isNotEmpty {
							resultText = resultText.replacingOccurrences(
								of: code, with: unicode)
						}
					}
				}
			})
		return resultText
	}

	public static func emojiAliases(key: String) -> String {
		guard let regex = emojiRegex else { return key }
		if regex.firstMatch(
			in: key, options: [], range: NSMakeRange(0, key.utf16.count)) != nil
		{
			return emojiCodes[key] ?? key
		}
		return key
	}
}
