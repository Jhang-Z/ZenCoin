import SwiftUI
import SwiftData

struct InsightView: View {
    @Environment(\.theme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.bookStore) private var bookStore

    @State private var viewModel: InsightViewModel?
    @State private var showingMonthPicker = false
    @State private var showingYearPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let vm = viewModel {
                    header(vm: vm)
                    if vm.totalExpense > 0 {
                        donutBlock(vm: vm)
                            .padding(.top, 16)
                        calendarBlock(vm: vm)
                            .padding(.top, 32)
                            .padding(.horizontal, 24)
                        breakdownList(vm: vm)
                            .padding(.top, 28)
                    } else {
                        emptyState
                    }
                    Color.clear.frame(height: 140)
                }
            }
        }
        .background(theme.bgPrimary.ignoresSafeArea())
        .onAppear {
            if viewModel == nil {
                viewModel = InsightViewModel(
                    modelContext: modelContext,
                    bookId: bookStore?.currentBookId ?? Book.defaultID
                )
            }
            viewModel?.setBook(bookStore?.currentBookId ?? Book.defaultID)
            viewModel?.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .expenseStoreDidChange)) { _ in
            viewModel?.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .currentBookDidChange)) { _ in
            viewModel?.setBook(bookStore?.currentBookId ?? Book.defaultID)
        }
        .sheet(isPresented: $showingMonthPicker) {
            if let vm = viewModel {
                MonthPickerSheet(initialYear: vm.year, initialMonth: vm.month) { y, m in
                    vm.setMonth(year: y, month: m)
                }
                .presentationBackground(theme.bgPrimary)
            }
        }
        .sheet(isPresented: $showingYearPicker) {
            if let vm = viewModel {
                YearPickerSheet(initialYear: vm.year) { y in
                    vm.setYear(y)
                }
                .presentationBackground(theme.bgPrimary)
            }
        }
    }

    // MARK: - Header

    @ViewBuilder
    private func header(vm: InsightViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    switch vm.scope {
                    case .month: showingMonthPicker = true
                    case .year:  showingYearPicker = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(vm.rangeLabel)
                            .font(theme.type.title)
                            .foregroundStyle(theme.textPrimary)
                            .tracking(theme.displayTracking * 0.4)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                scopeSegmented(vm: vm)
            }

            Text("EXPENSE / 支出")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .gesture(
            DragGesture(minimumDistance: 28)
                .onEnded { value in
                    let dx = value.translation.width
                    if abs(dx) < 60 { return }
                    vm.step(dx < 0 ? 1 : -1)
                }
        )
    }

    private func scopeSegmented(vm: InsightViewModel) -> some View {
        HStack(spacing: 0) {
            ForEach(InsightViewModel.Scope.allCases) { s in
                Button {
                    vm.scope = s
                    UISelectionFeedbackGenerator().selectionChanged()
                } label: {
                    Text(s.caps)
                        .font(theme.type.micro)
                        .tracking(0.8)
                        .foregroundStyle(vm.scope == s ? theme.bgPrimary : theme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: theme.radiusSmall)
                                .fill(vm.scope == s ? theme.textPrimary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: theme.radiusSmall + 2)
                .fill(theme.bgSurface)
        )
    }

    // MARK: - Donut block

    @ViewBuilder
    private func donutBlock(vm: InsightViewModel) -> some View {
        DonutChartView(
            slices: vm.donutSlices,
            centerTitle: CurrencyFormatter.format(vm.totalExpense),
            centerSubtitle: "\(vm.expenses.count) 笔"
        )
        .frame(height: 300)
        .padding(.horizontal, 24)
    }

    // MARK: - Calendar block

    @ViewBuilder
    private func calendarBlock(vm: InsightViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.scope == .month ? "DAILY / 每日" : "MONTHLY / 每月")
                .font(theme.type.micro)
                .tracking(0.8)
                .foregroundStyle(theme.textSecondary)
            switch vm.scope {
            case .month:
                CalendarHeatmapView(mode: .month(
                    days: vm.monthCalendarDays,
                    dayTotals: vm.dayTotals
                ))
            case .year:
                CalendarHeatmapView(mode: .year(
                    year: vm.year,
                    monthTotals: vm.monthTotals
                ))
            }
        }
    }

    // MARK: - Breakdown

    /// 与 DonutChartView 中的切片透明度阶梯保持一致。
    private static let opacityRamp: [Double] = [1.0, 0.85, 0.7, 0.55, 0.4, 0.28]

    @ViewBuilder
    private func breakdownList(vm: InsightViewModel) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(vm.donutSlices.enumerated()), id: \.element.id) { idx, slice in
                row(slice: slice, opacity: Self.opacityRamp[min(idx, Self.opacityRamp.count - 1)])
                if idx < vm.donutSlices.count - 1 {
                    Rectangle().fill(theme.separator).frame(height: 1).padding(.horizontal, 24)
                }
            }
        }
    }

    private func row(slice: InsightViewModel.Slice, opacity: Double) -> some View {
        HStack(spacing: 14) {
            // 与 donut 切片同色的方块，作为图例
            // 12pt 方块用 2pt 角 — 是有意的「sub-token 微 chrome」级别，
            // 比 theme.radiusSmall (4-8pt) 更克制，避免在 12pt 方块上变成近圆形。
            RoundedRectangle(cornerRadius: 2)
                .fill(theme.accent.opacity(opacity))
                .frame(width: 12, height: 12)
            Text(slice.label)
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text("\(Int((slice.share * 100).rounded()))%")
                .font(theme.type.caption)
                .foregroundStyle(theme.textSecondary)
                .frame(width: 40, alignment: .trailing)
            Text(CurrencyFormatter.format(slice.amount))
                .font(theme.type.body)
                .foregroundStyle(theme.textPrimary)
                .frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack {
            Spacer().frame(height: 100)
            Text("此区间还没有支出")
                .font(theme.type.body)
                .foregroundStyle(theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
