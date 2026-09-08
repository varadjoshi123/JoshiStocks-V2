//
//  ActivitySection.swift
//  JoshiStocks
//
//  Transaction history added in V2.
//

import SwiftUI

struct ActivitySection: View {
    @ObservedObject var viewModel: ContentViewModel

    var body: some View {
        Section(header: Text("RECENT ACTIVITY")) {
            if viewModel.recentTransactions.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No trades yet")
                        .fontWeight(.semibold)
                    Text("Your buys and sells will appear here with execution price and realized P/L.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
            } else {
                ForEach(Array(viewModel.recentTransactions.prefix(5))) { transaction in
                    HStack(spacing: 12) {
                        Image(systemName: transaction.side == "BUY" ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(transaction.side == "BUY" ? .blue : .green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(transaction.side) \(transaction.stock_ticker)")
                                .fontWeight(.semibold)
                            Text("\(transaction.quantity) \(transaction.quantity == 1 ? "share" : "shares") @ \(getCurrencyFormat(value: transaction.price))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let date = transaction.createdAtDate {
                                Text(date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(getCurrencyFormat(value: transaction.gross_amount))
                                .fontWeight(.semibold)
                            if transaction.side == "SELL" {
                                Text("P/L \(getCurrencyFormat(value: transaction.realized_pnl))")
                                    .font(.caption)
                                    .foregroundColor(transaction.realized_pnl >= 0 ? .green : .red)
                            }
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }
}
