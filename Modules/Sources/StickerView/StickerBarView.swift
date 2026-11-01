//
//  StickerBarView.swift
//  OnlySwitch
//
//  Created by OpenAI on 2026/7/5.
//

import ComposableArchitecture
import Defines
import Extensions
import SwiftUI

struct StickerBarView: View {
    let store: StoreOf<StickerReducer>

    var body: some View {
        WithPerceptionTracking {
            HStack {
                if store.isHovering {
                    StickerCloseButton(
                        strokeColor: Color(nsColor: store.stickerColor.stroke),
                        action: closeSticker
                    )
                }

                StickerCollapsedTitle(
                    content: store.stickerContent,
                    isCollapsed: store.collaspeMode,
                    strokeColor: Color(nsColor: store.stickerColor.stroke)
                )

                if store.isHovering {
                    StickerBarButtons(store: store)
                }
            }
            .background(
                ZStack {
                    Rectangle()
                        .foregroundStyle(Color(nsColor: store.stickerColor.bar))
                    // The whole bar drags the window; buttons above still receive clicks.
                    WindowDragView(onDoubleClick: toggleCollapseMode)
                }
                .frame(height: 20)
            )
            .shadow(color: Color(.sRGBLinear, white: 0, opacity: 0.2), radius: 3)
        }
    }

    private func closeSticker() {
        store.send(.closeSticker)
    }

    private func toggleCollapseMode() {
        store.send(.toggleCollapseMode)
    }
}
