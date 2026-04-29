import Foundation

/// 关键词 → ExpenseCategory 的 deterministic 映射。
///
/// 命中即用，未命中返回 nil（调用方决定回退策略：手动选 / AI 兜底 / 默认 .other）。
enum CategoryGuesser {

    /// 输入：交易类型 + 商品名 + 交易对方（任意顺序），按支出/收入维度做关键词扫描。
    static func guess(_ texts: [String], isIncome: Bool) -> ExpenseCategory? {
        let blob = texts.joined(separator: " ")
        let table = isIncome ? incomeTable : expenseTable
        for (kw, cat) in table where blob.contains(kw) {
            return cat
        }
        return nil
    }

    /// 顺序敏感：先匹配更具体的词。
    private static let expenseTable: [(String, ExpenseCategory)] = [
        // dining
        ("餐饮", .dining), ("餐厅", .dining), ("美食", .dining), ("外卖", .dining),
        ("美团", .dining), ("饿了么", .dining), ("星巴克", .dining), ("瑞幸", .dining),
        ("肯德基", .dining), ("麦当劳", .dining), ("汉堡王", .dining), ("奶茶", .dining),
        ("食堂", .dining), ("烧烤", .dining), ("火锅", .dining),
        // transport
        ("地铁", .transport), ("公交", .transport), ("滴滴", .transport), ("高德", .transport),
        ("出租", .transport), ("12306", .transport), ("加油", .transport), ("ETC", .transport),
        ("停车", .transport), ("打车", .transport),
        // shopping
        ("京东", .shopping), ("淘宝", .shopping), ("天猫", .shopping), ("拼多多", .shopping),
        ("唯品会", .shopping), ("小米", .shopping),
        // daily
        ("超市", .daily), ("便利店", .daily), ("永辉", .daily), ("盒马", .daily),
        ("山姆", .daily), ("Costco", .daily), ("沃尔玛", .daily), ("家乐福", .daily),
        // fun
        ("电影", .fun), ("演唱会", .fun), ("游戏", .fun), ("大麦", .fun),
        ("Steam", .fun), ("网易云", .fun), ("QQ 音乐", .fun), ("QQ音乐", .fun), ("B 站", .fun),
        ("B站", .fun), ("哔哩哔哩", .fun), ("KTV", .fun),
        // housing
        ("房租", .housing), ("物业", .housing), ("水费", .housing), ("电费", .housing),
        ("燃气", .housing), ("水电", .housing),
        // medical
        ("医院", .medical), ("药店", .medical), ("健康", .medical), ("挂号", .medical),
        ("诊所", .medical),
        // clothing
        ("优衣库", .clothing), ("Zara", .clothing), ("H&M", .clothing), ("Nike", .clothing),
        ("Adidas", .clothing), ("服饰", .clothing), ("服装", .clothing),
        // telecom
        ("移动", .telecom), ("联通", .telecom), ("电信", .telecom), ("话费", .telecom),
        ("流量", .telecom),
        // travel
        ("携程", .travel), ("飞猪", .travel), ("航空", .travel), ("机票", .travel),
        ("酒店", .travel), ("Airbnb", .travel), ("booking", .travel),
        // education
        ("学费", .education), ("课程", .education), ("培训", .education), ("网课", .education),
        ("得到", .education), ("书店", .education),
    ]

    private static let incomeTable: [(String, ExpenseCategory)] = [
        ("工资", .salary), ("薪资", .salary),
        ("奖金", .bonus), ("年终奖", .bonus),
        ("余额宝", .invest), ("理财", .invest), ("基金", .invest), ("股票", .invest),
        ("分红", .invest), ("利息", .invest),
    ]
}
