//
//  EPSChartsView.swift
//  StockTrade
//
//

import SwiftUI
import Charts

struct EPSChartsComponent: View {
    var epsChartsData: [StockEarningsElement]
    var isLoading: Bool

    private var sortedData: [StockEarningsElement] {
        epsChartsData.sorted { $0.period < $1.period }
    }

    private func periodLabel(_ period: String) -> String {
        if period.count >= 7 {
            return String(period.prefix(7))
        }
        return period
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Historical EPS Surprises")
                .font(.headline)

            if sortedData.isEmpty {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                        Text("Loading earnings history…")
                    } else {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                        Text("Earnings history unavailable")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                Chart {
                    ForEach(sortedData, id: \.period) { item in
                        LineMark(
                            x: .value("Period", periodLabel(item.period)),
                            y: .value("EPS", item.actual),
                            series: .value("Series", "Actual")
                        )
                        .foregroundStyle(by: .value("Series", "Actual"))
                        .symbol(by: .value("Series", "Actual"))

                        LineMark(
                            x: .value("Period", periodLabel(item.period)),
                            y: .value("EPS", item.estimate),
                            series: .value("Series", "Estimate")
                        )
                        .foregroundStyle(by: .value("Series", "Estimate"))
                        .symbol(by: .value("Series", "Estimate"))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom)
                .frame(height: 300)

                if let latest = sortedData.last {
                    HStack {
                        Text("Latest surprise")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2f", latest.surprise))
                            .fontWeight(.semibold)
                    }
                    .font(.footnote)
                }
            }
        }
        .padding(.horizontal)
    }
}
