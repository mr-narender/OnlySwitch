//
//  StickerChecklistTextConverter.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import AppKit

/// Maps Markdown checklist prefixes to inline checkbox attachments and back.
@MainActor
enum StickerChecklistTextConverter {
    private static let objectReplacement: unichar = 0xFFFC

    static func attributedString(
        from markdown: String,
        attributes: [NSAttributedString.Key: Any],
        tint: NSColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        for (index, line) in StickerChecklist.parse(markdown).enumerated() {
            if index > 0 {
                result.append(NSAttributedString(string: "\n", attributes: attributes))
            }
            switch line {
            case .text(let text):
                result.append(NSAttributedString(string: text, attributes: attributes))
            case .item(let checked, let body):
                let checkbox = NSMutableAttributedString(
                    attachment: StickerCheckboxAttachment(isChecked: checked, tint: tint)
                )
                checkbox.addAttributes(attributes, range: NSRange(location: 0, length: checkbox.length))
                result.append(checkbox)
                result.append(NSAttributedString(string: body, attributes: attributes))
            }
        }
        return result
    }

    static func markdown(from attributed: NSAttributedString) -> String {
        let string = attributed.string as NSString
        let replacement = String(utf16CodeUnits: [objectReplacement], count: 1)
        return lineRanges(in: string).map { range in
            let body = string.substring(with: range).replacingOccurrences(of: replacement, with: "")
            guard range.length > 0, let checkbox = checkbox(at: range.location, in: attributed) else {
                return body
            }
            return (checkbox.isChecked ? StickerChecklist.checkedPrefix : StickerChecklist.uncheckedPrefix) + body
        }
        .joined(separator: "\n")
    }

    static func position(forCharacterIndex index: Int, in attributed: NSAttributedString) -> StickerChecklistPosition {
        let ranges = lineRanges(in: attributed.string as NSString)
        let clamped = min(max(index, 0), attributed.length)
        let line = ranges.lastIndex { $0.location <= clamped } ?? 0
        let range = ranges[line]
        let offset = clamped - range.location
        return StickerChecklistPosition(
            line: line,
            bodyOffset: max(0, offset - prefixLength(ofLine: range, in: attributed))
        )
    }

    static func characterIndex(for position: StickerChecklistPosition, in attributed: NSAttributedString) -> Int {
        let ranges = lineRanges(in: attributed.string as NSString)
        guard ranges.indices.contains(position.line) else { return attributed.length }
        let range = ranges[position.line]
        let prefix = prefixLength(ofLine: range, in: attributed)
        let offset = min(max(position.bodyOffset, 0), range.length - prefix)
        return range.location + prefix + offset
    }

    /// True when the text contains typed or pasted Markdown prefixes, or orphaned
    /// replacement characters, that should be re-rendered as checkboxes.
    static func needsNormalization(_ attributed: NSAttributedString) -> Bool {
        if containsRawChecklistPrefix(attributed) { return true }
        return attributed.string.utf16.enumerated().contains { location, character in
            character == objectReplacement && checkbox(at: location, in: attributed) == nil
        }
    }

    static func containsRawChecklistPrefix(_ attributed: NSAttributedString) -> Bool {
        let string = attributed.string as NSString
        return lineRanges(in: string).contains { StickerChecklist.parseLine(string.substring(with: $0)).isItem }
    }

    // MARK: - Helpers

    /// Line ranges split on "\n", excluding the separator; always returns at least one range.
    private static func lineRanges(in string: NSString) -> [NSRange] {
        var ranges: [NSRange] = []
        var start = 0
        for location in 0..<string.length where string.character(at: location) == 0x0A {
            ranges.append(NSRange(location: start, length: location - start))
            start = location + 1
        }
        ranges.append(NSRange(location: start, length: string.length - start))
        return ranges
    }

    private static func checkbox(at location: Int, in attributed: NSAttributedString) -> StickerCheckboxAttachment? {
        guard location < attributed.length else { return nil }
        return attributed.attribute(.attachment, at: location, effectiveRange: nil) as? StickerCheckboxAttachment
    }

    /// Characters before the body: 1 for a checkbox, 6 for a raw Markdown prefix, else 0.
    private static func prefixLength(ofLine range: NSRange, in attributed: NSAttributedString) -> Int {
        if range.length > 0, checkbox(at: range.location, in: attributed) != nil {
            return 1
        }
        let line = (attributed.string as NSString).substring(with: range)
        return StickerChecklist.parseLine(line).isItem ? StickerChecklist.prefixLength : 0
    }
}
