import SwiftUI
import UIKit

extension View {
    /// 在视图的「空白区域」上 tap 自动收起键盘 —— 不影响子按钮 / TextField 的点击。
    /// 替代键盘 toolbar 的「完成」按钮，符合 zen「声音很小」原则：键盘是隐性 chrome，
    /// 不需要再加一个按钮提示用户怎么收起。
    func dismissKeyboardOnBackgroundTap() -> some View {
        self
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
    }
}
