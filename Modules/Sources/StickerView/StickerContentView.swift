//
//  StickerContentView.swift
//  OnlySwitch
//
//  Created by OpenAI on 2026/7/5.
//

import ComposableArchitecture
import SwiftUI

struct StickerContentView: View {
    @SwiftUI.Bindable var store: StoreOf<StickerReducer>

    var body: some View {
        WithPerceptionTracking {
            if store.previewMode {
                StickerMarkdownPreviewView(content: store.stickerContent)
            } else {
                StickerTextEditor(
                    text: $store.stickerContent,
                    tint: store.stickerColor.stroke.withAlphaComponent(1),
                    checklistToggleRequestID: store.checklistToggleRequestID
                )
                .frame(minWidth: 200, minHeight: 200)
            }
        }
    }
}
