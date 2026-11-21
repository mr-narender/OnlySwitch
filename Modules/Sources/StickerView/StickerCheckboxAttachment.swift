//
//  StickerCheckboxAttachment.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import AppKit

/// Inline checkbox shown in place of a `- [ ] ` / `- [x] ` prefix in the sticker editor.
final class StickerCheckboxAttachment: NSTextAttachment {
    let isChecked: Bool

    init(isChecked: Bool, tint: NSColor) {
        self.isChecked = isChecked
        super.init(data: nil, ofType: nil)
        attachmentCell = StickerCheckboxCell(isChecked: isChecked, tint: tint)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
