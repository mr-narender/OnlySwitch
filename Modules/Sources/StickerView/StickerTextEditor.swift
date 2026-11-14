//
//  StickerTextEditor.swift
//  OnlySwitch
//
//  Created by Jacklandrin on 2026/10/31.
//

import AppKit
import SwiftUI

/// Markdown-backed sticker editor that renders `- [ ]` / `- [x]` lines as clickable checkboxes.
struct StickerTextEditor: NSViewRepresentable {
    @Binding var text: String
    let tint: NSColor
    let checklistToggleRequestID: UUID?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(
            size: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        )
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = StickerNSTextView(frame: .zero, textContainer: textContainer)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.insertionPointColor = .black
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.typingAttributes = Coordinator.baseAttributes
        textView.onToggleChecklist = { [weak coordinator = context.coordinator] in
            coordinator?.toggleChecklistInSelection()
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        context.coordinator.textView = textView
        context.coordinator.load(text)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        if text != coordinator.lastMarkdown || tint != coordinator.renderedTint {
            coordinator.load(text)
        }
        if let requestID = checklistToggleRequestID, requestID != coordinator.lastHandledRequestID {
            coordinator.lastHandledRequestID = requestID
            // Defer so the binding is not mutated during a view update.
            Task { @MainActor in
                coordinator.toggleChecklistInSelection()
            }
        }
    }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        static let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.black
        ]

        var parent: StickerTextEditor
        weak var textView: StickerNSTextView?
        var lastMarkdown: String
        var renderedTint: NSColor?
        var lastHandledRequestID: UUID?
        private var isApplying = false

        init(parent: StickerTextEditor) {
            self.parent = parent
            self.lastMarkdown = parent.text
            // A request issued before this editor existed must not be replayed.
            self.lastHandledRequestID = parent.checklistToggleRequestID
        }

        /// Replaces the editor contents from Markdown without registering undo, keeping the caret position.
        func load(_ markdown: String) {
            guard let textView, let textStorage = textView.textStorage else { return }
            let position = caretPositions(in: textView)
            isApplying = true
            textStorage.setAttributedString(render(markdown))
            isApplying = false
            lastMarkdown = markdown
            renderedTint = parent.tint
            restoreSelection(position, in: textView)
        }

        func toggleChecklistInSelection() {
            guard let textView, let textStorage = textView.textStorage else { return }
            let selection = caretPositions(in: textView)
            let markdown = StickerChecklistTextConverter.markdown(from: textStorage)
            apply(
                StickerChecklist.toggleChecklist(
                    in: markdown,
                    lines: selection.start.line...lastSelectedLine(selection, in: textView)
                ),
                selection: selection
            )
        }

        // MARK: NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard !isApplying, let textView, let textStorage = textView.textStorage else { return }
            let undoManager = textView.undoManager
            let isUndoingOrRedoing = undoManager?.isUndoing == true || undoManager?.isRedoing == true
            if !isUndoingOrRedoing, !textView.hasMarkedText(),
               StickerChecklistTextConverter.needsNormalization(textStorage) {
                apply(StickerChecklistTextConverter.markdown(from: textStorage), selection: caretPositions(in: textView))
            } else {
                publish(StickerChecklistTextConverter.markdown(from: textStorage))
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)),
                  !textView.hasMarkedText(),
                  let textStorage = textView.textStorage
            else { return false }

            let selected = textView.selectedRange()
            guard let result = StickerChecklist.insertNewline(
                in: StickerChecklistTextConverter.markdown(from: textStorage.replacingCharacters(in: selected)),
                at: StickerChecklistTextConverter.position(forCharacterIndex: selected.location, in: textStorage)
            ) else { return false }

            apply(result.markdown, selection: (result.position, result.position))
            return true
        }

        func textView(
            _ textView: NSTextView,
            clickedOn cell: any NSTextAttachmentCellProtocol,
            in cellFrame: NSRect,
            at charIndex: Int
        ) {
            guard cell is StickerCheckboxCell, let textStorage = textView.textStorage else { return }
            let line = StickerChecklistTextConverter.position(forCharacterIndex: charIndex, in: textStorage).line
            apply(
                StickerChecklist.toggleItem(in: StickerChecklistTextConverter.markdown(from: textStorage), line: line),
                selection: caretPositions(in: textView)
            )
        }

        func textView(
            _ textView: NSTextView,
            shouldChangeTypingAttributes oldTypingAttributes: [String: Any] = [:],
            toAttributes newTypingAttributes: [NSAttributedString.Key: Any] = [:]
        ) -> [NSAttributedString.Key: Any] {
            // Never let typing inherit the checkbox attachment.
            newTypingAttributes.filter { $0.key != .attachment }
        }

        // MARK: Private

        private typealias Selection = (start: StickerChecklistPosition, end: StickerChecklistPosition)

        /// Replaces all text as one undoable edit and publishes the resulting Markdown.
        private func apply(_ markdown: String, selection: Selection) {
            guard let textView, let textStorage = textView.textStorage else { return }
            let attributed = render(markdown)
            let fullRange = NSRange(location: 0, length: textStorage.length)
            guard textView.shouldChangeText(in: fullRange, replacementString: attributed.string) else { return }
            isApplying = true
            textStorage.replaceCharacters(in: fullRange, with: attributed)
            textView.didChangeText()
            isApplying = false
            restoreSelection(selection, in: textView)
            textView.typingAttributes = Self.baseAttributes
            publish(markdown)
        }

        private func publish(_ markdown: String) {
            lastMarkdown = markdown
            if parent.text != markdown {
                parent.text = markdown
            }
        }

        private func render(_ markdown: String) -> NSAttributedString {
            StickerChecklistTextConverter.attributedString(
                from: markdown,
                attributes: Self.baseAttributes,
                tint: parent.tint
            )
        }

        private func caretPositions(in textView: NSTextView) -> Selection {
            let range = textView.selectedRange()
            let text = textView.textStorage ?? NSAttributedString()
            return (
                StickerChecklistTextConverter.position(forCharacterIndex: range.location, in: text),
                StickerChecklistTextConverter.position(forCharacterIndex: NSMaxRange(range), in: text)
            )
        }

        /// A multi-line selection ending at the start of a line does not include that line.
        private func lastSelectedLine(_ selection: Selection, in textView: NSTextView) -> Int {
            let range = textView.selectedRange()
            guard range.length > 0, selection.end.line > selection.start.line,
                  let textStorage = textView.textStorage
            else { return selection.end.line }
            let lineStart = StickerChecklistTextConverter.characterIndex(
                for: StickerChecklistPosition(line: selection.end.line, bodyOffset: 0),
                in: textStorage
            )
            let endsAtLineStart = NSMaxRange(range) <= lineStart
            return endsAtLineStart ? selection.end.line - 1 : selection.end.line
        }

        private func restoreSelection(_ selection: Selection, in textView: NSTextView) {
            guard let textStorage = textView.textStorage else { return }
            let start = StickerChecklistTextConverter.characterIndex(for: selection.start, in: textStorage)
            let end = StickerChecklistTextConverter.characterIndex(for: selection.end, in: textStorage)
            textView.setSelectedRange(NSRange(location: start, length: max(0, end - start)))
        }
    }
}

private extension NSAttributedString {
    /// The text with `range` removed, used so Return replaces a selection before splitting the line.
    func replacingCharacters(in range: NSRange) -> NSAttributedString {
        guard range.length > 0 else { return self }
        let copy = NSMutableAttributedString(attributedString: self)
        copy.deleteCharacters(in: range)
        return copy
    }
}
