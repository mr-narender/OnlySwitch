//
//  StickerCheckboxCell.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import AppKit

/// Draws the circular checkbox used by `StickerCheckboxAttachment`.
final class StickerCheckboxCell: NSTextAttachmentCell {
    private let isChecked: Bool
    private let tint: NSColor
    private static let diameter: CGFloat = 16

    init(isChecked: Bool, tint: NSColor) {
        self.isChecked = isChecked
        self.tint = tint
        super.init(textCell: "")
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func cellSize() -> NSSize {
        NSSize(width: Self.diameter + 7, height: Self.diameter)
    }

    override func cellBaselineOffset() -> NSPoint {
        NSPoint(x: 0, y: -3)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        let circleRect = NSRect(
            x: cellFrame.minX + 1,
            y: cellFrame.midY - Self.diameter / 2,
            width: Self.diameter,
            height: Self.diameter
        ).insetBy(dx: 0.75, dy: 0.75)
        let circle = NSBezierPath(ovalIn: circleRect)

        guard isChecked else {
            tint.setStroke()
            circle.lineWidth = 1.5
            circle.stroke()
            return
        }

        tint.withAlphaComponent(0.85).setFill()
        circle.fill()

        // Checkmark points expressed top-down, flipped when the view is not flipped.
        let flipped = controlView?.isFlipped ?? true
        func point(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
            let dy = circleRect.height * y
            return NSPoint(
                x: circleRect.minX + circleRect.width * x,
                y: flipped ? circleRect.minY + dy : circleRect.maxY - dy
            )
        }
        let check = NSBezierPath()
        check.move(to: point(0.27, 0.52))
        check.line(to: point(0.44, 0.69))
        check.line(to: point(0.74, 0.33))
        check.lineWidth = 1.8
        check.lineCapStyle = .round
        check.lineJoinStyle = .round
        NSColor.white.setStroke()
        check.stroke()
    }
}
