//
//  HourlyChartView.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/29/24.
//

import SwiftUI
import Charts

struct HourlyChartComponent: View {
    var stockTicker: String
    var hourlyChartData: [PointDetails]
    var changeInPrice: Double
    var isLoading: Bool

    private var recentData: [PointDetails] {
        guard let latest = hourlyChartData.max(by: { $0.t < $1.t })?.t else { return [] }
        let sixHours: Int64 = 6 * 60 * 60 * 1000
        return hourlyChartData
            .filter { latest - $0.t <= sixHours }
            .sorted { $0.t < $1.t }
    }

    private var lineColor: Color {
        if abs(changeInPrice) < 0.005 { return .secondary }
        return changeInPrice > 0 ? .green : .red
    }

    private var yDomain: ClosedRange<Double>? {
        let values = recentData.map(\.c)
        guard let minValue = values.min(), let maxValue = values.max() else { return nil }
        if abs(maxValue - minValue) < 0.01 {
            return (minValue - 1)...(maxValue + 1)
        }
        let padding = max((maxValue - minValue) * 0.12, 0.5)
        return (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(stockTicker) Intraday")
                .font(.headline)

            if recentData.isEmpty {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                        Text("Loading intraday chart…")
                    } else {
                        Image(systemName: "chart.xyaxis.line")
                        Text("Intraday chart unavailable")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                Chart(recentData, id: \.t) { point in
                    LineMark(
                        x: .value("Time", Date(timeIntervalSince1970: TimeInterval(point.t) / 1000)),
                        y: .value("Price", point.c)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    AreaMark(
                        x: .value("Time", Date(timeIntervalSince1970: TimeInterval(point.t) / 1000)),
                        yStart: .value("Baseline", yDomain?.lowerBound ?? point.c),
                        yEnd: .value("Price", point.c)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.22), lineColor.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartYScale(domain: yDomain ?? 0...1)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour().minute())
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
                .frame(height: 300)
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}
