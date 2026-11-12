//
//  ListDetailSplitView.swift
//  PayLog
//

import SwiftUI

/// 一覧と詳細を、広い画面（iPhone Duo の内側の画面など）では左右に並べ、
/// 狭い画面では一覧から詳細へ進む1列の表示にまとめる。
struct ListDetailSplitView<Selection: Hashable, Sidebar: View, Detail: View>: View {
    /// 詳細側に表示するもの。変わるたびに、詳細側の画面の積み重ねを作り直す。
    @Binding var selection: Selection?
    @ViewBuilder let sidebar: Sidebar
    @ViewBuilder let detail: Detail

    var body: some View {
        NavigationSplitView(preferredCompactColumn: compactColumn) {
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

    /// 1列の表示では、選択があれば詳細を、なければ一覧を出す。
    /// 一覧の行以外（ツールバーのボタンなど）から選択を変えたときも、詳細へ切り替わる。
    private var compactColumn: Binding<NavigationSplitViewColumn> {
        Binding {
            selection == nil ? .sidebar : .detail
        } set: { column in
            if column == .sidebar {
                selection = nil
            }
        }
    }
}

extension View {
    /// 並べ替えの編集中は、行をタップしても詳細を開かない
    func selectionDisabledWhileEditing() -> some View {
        modifier(SelectionDisabledWhileEditing())
    }
}

private struct SelectionDisabledWhileEditing: ViewModifier {
    @Environment(\.editMode) private var editMode

    func body(content: Content) -> some View {
        content.selectionDisabled(editMode?.wrappedValue.isEditing == true)
    }
}
