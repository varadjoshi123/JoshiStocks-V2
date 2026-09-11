//
//  RecommendationTrendsChartView.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/29/24.
//

import SwiftUI
import Charts

struct RecommendationTrendsChartComponent: View {
    var recommendationTrendsSeriesData: [StockRecommendationElement]
    var isLoading: Bool

    private var recentData: [StockRecommendationElement] {
        Array(recommendationTrendsSeriesData.prefix(6).reversed())
    }

    private func periodLabel(_ period: String) -> String {
        if period.count >= 7 {
            return String(period.prefix(7))
        }
        return period
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendation Trends")
                .font(.headline)

            if recentData.isEmpty {
                VStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                        Text("Loading analyst recommendations…")
                    } else {
                        Image(systemName: "person.3")
                        Text("Analyst recommendations unavailable")
                    }
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                Chart(recentData, id: \.period) { item in
                    BarMark(
                        x: .value("Period", periodLabel(item.period)),
                        y: .value("Analysts", item.strongBuy)
                    )
                    .foregroundStyle(by: .value("Rating", "Strong Buy"))

                    BarMark(
                        x: .value("Period", periodLabel(item.period)),
                        y: .value("Analysts", item.buy)
                    )
                    .foregroundStyle(by: .value("Rating", "Buy"))

                    BarMark(
                        x: .value("Period", periodLabel(item.period)),
                        y: .value("Analysts", item.hold)
                    )
                    .foregroundStyle(by: .value("Rating", "Hold"))

                    BarMark(
                        x: .value("Period", periodLabel(item.period)),
                        y: .value("Analysts", item.sell)
                    )
                    .foregroundStyle(by: .value("Rating", "Sell"))

                    BarMark(
                        x: .value("Period", periodLabel(item.period)),
                        y: .value("Analysts", item.strongSell)
                    )
                    .foregroundStyle(by: .value("Rating", "Strong Sell"))
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: 8)
                .frame(height: 300)
            }
        }
        .padding(.horizontal)
    }
}
