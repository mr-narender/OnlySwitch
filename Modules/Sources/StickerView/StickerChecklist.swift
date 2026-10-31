//
//  StickerChecklist.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import Foundation

/// One line of sticker content, either plain text or a Markdown task-list item.
public enum StickerChecklistLine: Equatable, Sendable {
    case text(String)
    case item(checked: Bool, body: String)
}

/// A caret location expressed independently of how the checklist prefix is rendered.
/// `bodyOffset` counts UTF-16 units after the checklist prefix (or from the line start for text).
public struct StickerChecklistPosition: Equatable, Sendable {
    public var line: Int
    public var bodyOffset: Int

    public init(line: Int, bodyOffset: Int) {
        self.line = line
        self.bodyOffset = bodyOffset
    }
}

/// Pure transforms for Markdown checklists (`- [ ] ` / `- [x] `) stored in sticker content.
public enum StickerChecklist {
    public static let uncheckedPrefix = "- [ ] "
    public static let checkedPrefix = "- [x] "
    static let prefixLength = 6

    public static func parseLine(_ line: String) -> StickerChecklistLine {
        let prefix = Array(line.prefix(prefixLength))
        guard prefix.count == prefixLength,
              prefix[0] == "-" || prefix[0] == "*",
              prefix[1] == " ",
              prefix[2] == "[",
              prefix[4] == "]",
              prefix[5] == " "
        else { return .text(line) }

        let body = String(line.dropFirst(prefixLength))
        switch prefix[3] {
        case " ":
            return .item(checked: false, body: body)
        case "x", "X":
            return .item(checked: true, body: body)
        default:
            return .text(line)
        }
    }

    public static func parse(_ markdown: String) -> [StickerChecklistLine] {
        markdown.components(separatedBy: "\n").map(parseLine)
    }

    public static func serialize(_ lines: [StickerChecklistLine]) -> String {
        lines.map(serializeLine).joined(separator: "\n")
    }

    static func serializeLine(_ line: StickerChecklistLine) -> String {
        switch line {
        case .text(let text):
            return text
        case .item(let checked, let body):
            return (checked ? checkedPrefix : uncheckedPrefix) + body
        }
    }

    /// Converts the lines to unchecked items, or back to text when every line is already an item.
    public static func toggleChecklist(in markdown: String, lines range: ClosedRange<Int>) -> String {
        var lines = parse(markdown)
        let indices = range.clamped(to: 0...(lines.count - 1))
        guard range.overlaps(0...(lines.count - 1)) else { return markdown }

        let allItems = indices.allSatisfy { lines[$0].isItem }
        for index in indices {
            switch lines[index] {
            case .text(let text) where !allItems:
                lines[index] = .item(checked: false, body: text)
            case .item(_, let body) where allItems:
                lines[index] = .text(body)
            default:
                break
            }
        }
        return serialize(lines)
    }

    public static func toggleItem(in markdown: String, line: Int) -> String {
        var lines = parse(markdown)
        guard lines.indices.contains(line), case .item(let checked, let body) = lines[line] else {
            return markdown
        }
        lines[line] = .item(checked: !checked, body: body)
        return serialize(lines)
    }

    /// Handles Return on a checklist line. Returns `nil` for text lines so the editor inserts a plain newline.
    public static func insertNewline(
        in markdown: String,
        at position: StickerChecklistPosition
    ) -> (markdown: String, position: StickerChecklistPosition)? {
        var lines = parse(markdown)
        guard lines.indices.contains(position.line),
              case .item(let checked, let body) = lines[position.line]
        else { return nil }

        if body.isEmpty {
            lines[position.line] = .text("")
            return (serialize(lines), StickerChecklistPosition(line: position.line, bodyOffset: 0))
        }

        let utf16 = body.utf16
        let offset = min(max(position.bodyOffset, 0), utf16.count)
        let splitIndex = utf16.index(utf16.startIndex, offsetBy: offset)
        let head = String(utf16[..<splitIndex]) ?? body
        let tail = String(utf16[splitIndex...]) ?? ""

        lines[position.line] = .item(checked: checked, body: head)
        lines.insert(.item(checked: false, body: tail), at: position.line + 1)
        return (serialize(lines), StickerChecklistPosition(line: position.line + 1, bodyOffset: 0))
    }

    /// The first non-empty line, without its checklist prefix, used as the collapsed title.
    public static func title(from markdown: String) -> String {
        for line in parse(markdown) {
            let text = line.body
            if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                return text
            }
        }
        return ""
    }
}

extension StickerChecklistLine {
    var isItem: Bool {
        if case .item = self { return true }
        return false
    }

    var body: String {
        switch self {
        case .text(let text): return text
        case .item(_, let body): return body
        }
    }
}
