//
//  PortfolioSection.swift
//  StockTrade / JoshiStocks
//

import SwiftUI

struct PortfolioSection: View {
    @ObservedObject var viewModel: ContentViewModel

    private func pnlColor(_ value: Double) -> Color {
        if abs(value) < 0.005 { return .secondary }
        return value > 0 ? .green : .red
    }

    var body: some View {
        Section(header: Text("PORTFOLIO")) {
            HStack {
                metric("Net Worth", getCurrencyFormat(value: viewModel.netWorth))
                Spacer()
                metric("Cash", getCurrencyFormat(value: viewModel.cashBalance))
            }

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unrealized P/L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(getCurrencyFormat(value: viewModel.unrealizedPnl))
                        .fontWeight(.semibold)
                        .foregroundColor(pnlColor(viewModel.unrealizedPnl))
                    Text(getPercentageFormat(value: viewModel.unrealizedPnlPercent))
                        .font(.caption)
                        .foregroundColor(pnlColor(viewModel.unrealizedPnl))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Realized P/L")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(getCurrencyFormat(value: viewModel.realizedPnl))
                        .fontWeight(.semibold)
                        .foregroundColor(pnlColor(viewModel.realizedPnl))
                    Text("Total \(getCurrencyFormat(value: viewModel.totalPnl))")
                        .font(.caption)
                        .foregroundColor(pnlColor(viewModel.totalPnl))
                }
            }
            .padding(.vertical, 2)

            if viewModel.stocksDataForPortfolio.isEmpty {
                Text("Your portfolio is empty. Search for a stock to place your first paper trade.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
            } else {
                ForEach($viewModel.stocksDataForPortfolio, id: \.self.id) { element in
                    NavigationLink(destination: StockDetails(stock_ticker: element.stock_ticker.wrappedValue, viewModel: self.viewModel)) {
                        VStack {
                            HStack {
                                Text(element.stock_ticker.wrappedValue)
                                    .font(.system(size: 22))
                                    .fontWeight(.semibold)
                                Spacer()
                                Text(getCurrencyFormat(value: element.market_value.wrappedValue ?? 0.0))
                                    .fontWeight(.semibold)
                            }
                            HStack {
                                Text("\(element.quantity.wrappedValue) shares")
                                    .foregroundColor(.secondary)
                                Spacer()
                                let pnl = element.change_in_price.wrappedValue ?? 0.0
                                Image(systemName: abs(pnl) < 0.005 ? "minus" : (pnl > 0 ? "arrow.up.forward" : "arrow.down.forward"))
                                    .foregroundColor(pnlColor(pnl))
                                (Text(getCurrencyFormat(value: pnl)) + Text(" (") + Text(getPercentageFormat(value: element.change_in_price_percentage.wrappedValue ?? 0.0)) + Text(")"))
                                    .foregroundColor(pnlColor(pnl))
                            }
                            .font(.system(size: 15))
                        }
                    }
                }
                .onMove { indices, newOffset in
                    viewModel.stocksDataForPortfolio.move(fromOffsets: indices, toOffset: newOffset)
                    withAnimation { viewModel.isEditable = false }
                }
                .onLongPressGesture {
                    withAnimation { viewModel.isEditable = true }
                }
            }
        }
        .onReceive(viewModel.timer) { _ in
            viewModel.updateStockDataList()
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 20, weight: .bold))
        }
    }
}
