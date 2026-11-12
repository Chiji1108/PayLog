//
//  ListDetailSplitView.swift
//  PayLog
//

import SwiftUI

/// 一覧と詳細を、広い画面（iPhone Duo の内側の画面など）では左右に並べ、
/// 狭い画面では一覧から詳細へ進む1列の表示にまとめる。
struct ListDetailSplitView<Selection: Hashable, Sidebar: View, Detail: View>: View {
    /// 一覧で選ばれているもの。変わるたびに、詳細側の画面の積み重ねを作り直す。
    let selection: Selection?
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let detail: Detail

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 320, ideal: 420)
        } detail: {
            // 詳細から先の画面（支払いカードなど）へ進めるよう、詳細側にも画面の積み重ねを持たせる
            NavigationStack {
                detail
            }
            .id(selection)
        }
        .navigationSplitViewStyle(.balanced)
    }
}
