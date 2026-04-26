import UIKit

/// 一键安装快捷指令的入口。把你 export 出来的 .shortcut iCloud 链接粘到 `iCloudLink` 即可。
/// 链接为空时，fallback 是直接打开「快捷指令」app。
enum ShortcutInstallerService {
    /// 把你分享出去的快捷指令 iCloud 链接粘在这里。
    /// 例如：`https://www.icloud.com/shortcuts/xxxxxxxxx`
    static let iCloudLink: String = ""

    static var hasICloudLink: Bool {
        !iCloudLink.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @MainActor
    static func install() {
        if let url = URL(string: iCloudLink), hasICloudLink {
            UIApplication.shared.open(url)
            return
        }
        if let fallback = URL(string: "shortcuts://") {
            UIApplication.shared.open(fallback)
        }
    }
}
