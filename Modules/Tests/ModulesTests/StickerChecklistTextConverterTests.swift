#if os(macOS)
import AppKit
import Testing
@testable import StickerView

@MainActor
struct StickerChecklistTextConverterTests {
    private func attributed(_ markdown: String) -> NSAttributedString {
        StickerChecklistTextConverter.attributedString(from: markdown, attributes: [:], tint: .black)
    }

    @Test func roundTripsMarkdown() {
        let markdown = "Title\n- [ ] a\n- [x] b\n"
        #expect(StickerChecklistTextConverter.markdown(from: attributed(markdown)) == markdown)
    }

    @Test func replacesEachPrefixWithOneCheckboxAttachment() {
        let text = attributed("- [ ] a\nplain\n- [x] b")
        #expect(text.string == "\u{FFFC}a\nplain\n\u{FFFC}b")

        let first = text.attribute(.attachment, at: 0, effectiveRange: nil) as? StickerCheckboxAttachment
        let second = text.attribute(.attachment, at: 9, effectiveRange: nil) as? StickerCheckboxAttachment
        #expect(first?.isChecked == false)
        #expect(second?.isChecked == true)
    }

    @Test func dropsObjectReplacementCharactersWithoutCheckbox() {
        let text = NSAttributedString(string: "a\u{FFFC}b")
        #expect(StickerChecklistTextConverter.markdown(from: text) == "ab")
    }

    @Test func mapsCharacterIndexToPosition() {
        let text = attributed("x\n- [ ] ab")
        #expect(StickerChecklistTextConverter.position(forCharacterIndex: 1, in: text) == .init(line: 0, bodyOffset: 1))
        #expect(StickerChecklistTextConverter.position(forCharacterIndex: 2, in: text) == .init(line: 1, bodyOffset: 0))
        #expect(StickerChecklistTextConverter.position(forCharacterIndex: 3, in: text) == .init(line: 1, bodyOffset: 0))
        #expect(StickerChecklistTextConverter.position(forCharacterIndex: 5, in: text) == .init(line: 1, bodyOffset: 2))
    }

    @Test func mapsPositionToCharacterIndex() {
        let text = attributed("x\n- [ ] ab")
        #expect(StickerChecklistTextConverter.characterIndex(for: .init(line: 0, bodyOffset: 1), in: text) == 1)
        #expect(StickerChecklistTextConverter.characterIndex(for: .init(line: 1, bodyOffset: 0), in: text) == 3)
        #expect(StickerChecklistTextConverter.characterIndex(for: .init(line: 1, bodyOffset: 9), in: text) == 5)
        #expect(StickerChecklistTextConverter.characterIndex(for: .init(line: 7, bodyOffset: 0), in: text) == 5)
    }

    @Test func mapsRawPrefixCaretIntoBody() {
        let raw = NSAttributedString(string: "- [ ] abc")
        #expect(StickerChecklistTextConverter.position(forCharacterIndex: 8, in: raw) == .init(line: 0, bodyOffset: 2))
    }

    @Test func detectsRawChecklistPrefixes() {
        #expect(StickerChecklistTextConverter.containsRawChecklistPrefix(NSAttributedString(string: "a\n- [ ] b")))
        #expect(!StickerChecklistTextConverter.containsRawChecklistPrefix(attributed("a\n- [ ] b")))
    }

    @Test func needsNormalizationForRawPrefixesAndOrphans() {
        #expect(StickerChecklistTextConverter.needsNormalization(NSAttributedString(string: "- [x] b")))
        #expect(StickerChecklistTextConverter.needsNormalization(NSAttributedString(string: "\u{FFFC}b")))
        #expect(!StickerChecklistTextConverter.needsNormalization(attributed("- [ ] a\nplain")))
    }
}
#endif
