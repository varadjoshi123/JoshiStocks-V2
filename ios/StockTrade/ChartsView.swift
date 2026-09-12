//
//  ChartsView.swift
//  StockTrade
//
//

import SwiftUI

struct ChartsView: View {
    @ObservedObject var stockModel: StockDetailsModel

    var body: some View {
        TabView {
            HourlyChartComponent(
                stockTicker: stockModel.stock_ticker,
                hourlyChartData: stockModel.hourly_chart_data,
                changeInPrice: stockModel.change_in_price,
                isLoading: !stockModel.hourlyChartDataUpdated
            )
            .tabItem {
                Label("Hourly", systemImage: "chart.xyaxis.line")
            }

            HistoricalChartComponent(
                stockTicker: stockModel.stock_ticker,
                historicalChartData: stockModel.historical_chart_data,
                isLoading: !stockModel.historicalChartDataUpdated
            )
            .tabItem {
                Label("Historical", systemImage: "clock")
            }
        }
        .frame(height: 440)
    }
}
