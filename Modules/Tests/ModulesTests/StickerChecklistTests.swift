#if os(macOS)
import Testing
@testable import StickerView

struct StickerChecklistTests {
    @Test func parsesChecklistPrefixes() {
        #expect(StickerChecklist.parseLine("- [ ] Milk") == .item(checked: false, body: "Milk"))
        #expect(StickerChecklist.parseLine("- [x] A") == .item(checked: true, body: "A"))
        #expect(StickerChecklist.parseLine("- [X] A") == .item(checked: true, body: "A"))
        #expect(StickerChecklist.parseLine("* [ ] A") == .item(checked: false, body: "A"))
        #expect(StickerChecklist.parseLine("- [ ] ") == .item(checked: false, body: ""))
    }

    @Test func leavesNonChecklistLinesAsText() {
        #expect(StickerChecklist.parseLine("-[ ] A") == .text("-[ ] A"))
        #expect(StickerChecklist.parseLine("  - [ ] A") == .text("  - [ ] A"))
        #expect(StickerChecklist.parseLine("- [ ]") == .text("- [ ]"))
        #expect(StickerChecklist.parseLine("Milk") == .text("Milk"))
    }

    @Test func roundTripsCanonicalMarkdown() {
        let markdown = "Title\n- [ ] a\n- [x] b\n\nend\n"
        #expect(StickerChecklist.serialize(StickerChecklist.parse(markdown)) == markdown)
    }

    @Test func normalizesAlternatePrefixesWhenSerializing() {
        #expect(StickerChecklist.serialize(StickerChecklist.parse("* [X] a")) == "- [x] a")
    }

    @Test func togglingTextLinesAddsUncheckedItems() {
        #expect(StickerChecklist.toggleChecklist(in: "a\nb", lines: 0...1) == "- [ ] a\n- [ ] b")
    }

    @Test func togglingMixedRangeKeepsExistingItems() {
        #expect(StickerChecklist.toggleChecklist(in: "- [x] a\nb", lines: 0...1) == "- [x] a\n- [ ] b")
    }

    @Test func togglingAllItemsRemovesChecklist() {
        #expect(StickerChecklist.toggleChecklist(in: "- [x] a\n- [ ] b", lines: 0...1) == "a\nb")
    }

    @Test func togglingClampsOutOfRangeLines() {
        #expect(StickerChecklist.toggleChecklist(in: "a", lines: 0...5) == "- [ ] a")
        #expect(StickerChecklist.toggleChecklist(in: "a", lines: 3...5) == "a")
    }

    @Test func toggleItemFlipsCheckedState() {
        #expect(StickerChecklist.toggleItem(in: "- [ ] a", line: 0) == "- [x] a")
        #expect(StickerChecklist.toggleItem(in: "x\n- [x] a", line: 1) == "x\n- [ ] a")
        #expect(StickerChecklist.toggleItem(in: "a", line: 0) == "a")
        #expect(StickerChecklist.toggleItem(in: "a", line: 4) == "a")
    }

    @Test func newlineSplitsItemIntoNewUncheckedItem() throws {
        let result = try #require(
            StickerChecklist.insertNewline(in: "- [x] milk", at: .init(line: 0, bodyOffset: 2))
        )
        #expect(result.markdown == "- [x] mi\n- [ ] lk")
        #expect(result.position == .init(line: 1, bodyOffset: 0))
    }

    @Test func newlineOnEmptyItemEndsChecklist() throws {
        let result = try #require(
            StickerChecklist.insertNewline(in: "- [ ] a\n- [ ] ", at: .init(line: 1, bodyOffset: 0))
        )
        #expect(result.markdown == "- [ ] a\n")
        #expect(result.position == .init(line: 1, bodyOffset: 0))
    }

    @Test func newlineOnTextLineUsesDefaultBehavior() {
        #expect(StickerChecklist.insertNewline(in: "milk", at: .init(line: 0, bodyOffset: 2)) == nil)
    }

    @Test func titleSkipsEmptyLinesAndChecklistPrefix() {
        #expect(StickerChecklist.title(from: "\n- [x] Buy milk\nmore") == "Buy milk")
        #expect(StickerChecklist.title(from: "Plain\n- [ ] a") == "Plain")
        #expect(StickerChecklist.title(from: "") == "")
    }
}
#endif
