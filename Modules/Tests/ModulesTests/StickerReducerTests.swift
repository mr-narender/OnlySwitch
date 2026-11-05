#if os(macOS)
import ComposableArchitecture
import Foundation
import Testing
@testable import StickerView

@MainActor
struct StickerReducerTests {
    @Test func toggleChecklistIssuesUniqueEditorRequests() async {
        let store = TestStore(initialState: StickerReducer.State(sticker: StickerModel(id: "a"))) {
            StickerReducer()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        await store.send(.toggleChecklist) {
            $0.checklistToggleRequestID = UUID(0)
        }
        await store.send(.toggleChecklist) {
            $0.checklistToggleRequestID = UUID(1)
        }
    }
}
#endif
