//
//  StickerCollapsedTitle.swift
//  OnlySwitch
//
//  Created by OpenAI on 2026/7/5.
//

import SwiftUI

struct StickerCollapsedTitle: View {
    let content: String
    let isCollapsed: Bool
    let strokeColor: Color

    var body: some View {
        ZStack {
            if isCollapsed {
                Text(StickerChecklist.title(from: content))
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundStyle(strokeColor)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 20, maxHeight: 20)
    }
}
