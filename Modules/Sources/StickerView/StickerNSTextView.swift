//
//  StickerNSTextView.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import AppKit

/// TextKit 1 text view that copies checklists as Markdown and handles the ⇧⌘L checklist shortcut.
final class StickerNSTextView: NSTextView {
    var onToggleChecklist: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers == [.command, .shift], event.charactersIgnoringModifiers?.lowercased() == "l" {
            onToggleChecklist?()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        guard let textStorage else { return super.writeSelection(to: pboard, types: types) }
        let markdown = selectedRanges
            .map(\.rangeValue)
            .filter { $0.length > 0 }
            .map { StickerChecklistTextConverter.markdown(from: textStorage.attributedSubstring(from: $0)) }
            .joined(separator: "\n")
        guard !markdown.isEmpty else { return false }
        pboard.clearContents()
        return pboard.setString(markdown, forType: .string)
    }
}
