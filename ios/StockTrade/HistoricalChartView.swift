//
//  HistoricalChartView.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/29/24.
//

import SwiftUI
import Charts

enum HistoricalChartRange: String, CaseIterable, Identifiable {
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case twoYears = "2Y"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .oneMonth: return 31
        case .threeMonths: return 93
        case .sixMonths: return 186
        case .oneYear: return 366
        case .twoYears: return 732
        }
    }
}

struct HistoricalChartComponent: View {
    var stockTicker: String
    var historicalChartData: [PointDetails]
    var isLoading: Bool
    @State private var selectedRange: HistoricalChartRange = .sixMonths

    private var filteredData: [PointDetails] {
        let sorted = historicalChartData.sorted { $0.t < $1.t }
        guard let latest = sorted.last?.t else { return [] }
        let cutoff = latest - Int64(selectedRange.days) * 24 * 60 * 60 * 1000
        return sorted.filter { $0.t >= cutoff }
    }

    private var yDomain: ClosedRange<Double>? {
        let values = filteredData.map(\.c)
        guard let minValue = values.min(), let maxValue = values.max() else { return nil }
        if abs(maxValue - minValue) < 0.01 {
            return (minValue - 1)...(maxValue + 1)
        }
        let padding = max((maxValue - minValue) * 0.08, 0.5)
        return (minValue - padding)...(maxValue + padding)
    }

    private var periodChange: Double {
        guard let first = filteredData.first?.c, let last = filteredData.last?.c else { return 0 }
        return last - first
    }

    private var lineColor: Color {
        if abs(periodChange) < 0.005 { return .secondary }
        return periodChange > 0 ? .green : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(stockTicker) History")
                    .font(.headline)
                Spacer()
                if !filteredData.isEmpty {
                    Text(getCurrencyFormat(value: periodChange))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(lineColor)
                }
            }

            Picker("Range", selection: $selectedRange) {
                ForEach(HistoricalChartRange.allCases) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)

            if filteredData.isEmpty {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                        Text("Loading historical chart…")
                    } else {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Historical chart unavailable")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                Chart(filteredData, id: \.t) { point in
                    LineMark(
                        x: .value("Date", Date(timeIntervalSince1970: TimeInterval(point.t) / 1000)),
                        y: .value("Close", point.c)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYScale(domain: yDomain ?? 0...1)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let price = value.as(Double.self) {
                                Text(price, format: .currency(code: "USD").precision(.fractionLength(0...2)))
                            }
                        }
                    }
                }
                .frame(height: 250)
            }
        }
        .padding(.horizontal)
        .padding(.top, 24)
    }
}
