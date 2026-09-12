//
//  TradeSheetView.swift
//  StockTrade
//
//

import SwiftUI

struct TradeSheetView: View {
    var stock_info: StockInfoData
    var stockPortfolioData: PortFolioElement
    var cashBalance: Double
    var current_price: Double

    var stockModel: StockDetailsModel
    var stockDetailsView: StockDetails
    var viewModel: ContentViewModel

    @State private var displayTradeSuccessfulSheet = false
    @State private var quantityText = ""
    @State private var isShowingToast = false
    @State private var toastMessage: Text = Text("")
    @State private var allStocksSold = false
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss

    private var quantity: Int64 {
        Int64(quantityText) ?? 0
    }

    private var estimatedValue: Double {
        current_price * Double(quantity)
    }

    private var ownedShares: Int64 {
        stockPortfolioData.quantity
    }

    private func showError(_ message: String) {
        toastMessage = Text(message)
        isShowingToast = true
    }

    private func submit(_ side: String) {
        guard quantity > 0 else {
            showError("Enter a positive whole number of shares.")
            return
        }

        if side == "BUY" && estimatedValue > cashBalance + 0.001 {
            showError("Not enough cash for this purchase.")
            return
        }

        if side == "SELL" && quantity > ownedShares {
            showError("You only own \(ownedShares) \(ownedShares == 1 ? "share" : "shares") of \(stock_info.ticker).")
            return
        }

        isSubmitting = true
        executeTrade(
            stock_ticker: stockPortfolioData.stock_ticker,
            stock_company: stockPortfolioData.stock_company,
            side: side,
            quantity: quantity
        ) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success(let response):
                    stockModel.successfulToastMessage = response.message
                    allStocksSold = side == "SELL" && ownedShares == quantity
                    displayTradeSuccessfulSheet = true
                case .failure(let error):
                    showError(error.localizedDescription)
                }
            }
        }
    }

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                }
            }

            Text("Trade \(stock_info.name)")
                .font(.title3.weight(.semibold))

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField("0", text: $quantityText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .font(.system(size: 72, weight: .thin))
                    .onChange(of: quantityText) { _, newValue in
                        quantityText = newValue.filter { $0.isNumber }
                    }

                Text(quantity == 1 ? "Share" : "Shares")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                HStack {
                    Text("Market price")
                    Spacer()
                    Text(getCurrencyFormat(value: current_price))
                }
                HStack {
                    Text("Estimated value")
                    Spacer()
                    Text(getCurrencyFormat(value: estimatedValue))
                        .fontWeight(.semibold)
                }
                HStack {
                    Text("Available cash")
                    Spacer()
                    Text(getCurrencyFormat(value: cashBalance))
                }
                HStack {
                    Text("Shares owned")
                    Spacer()
                    Text("\(ownedShares)")
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()

            if isSubmitting {
                ProgressView("Submitting trade…")
                    .padding(.bottom, 4)
            }

            HStack(spacing: 12) {
                Button(action: { submit("BUY") }) {
                    Text("Buy")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                .disabled(isSubmitting)

                Button(action: { submit("SELL") }) {
                    Text("Sell")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.green)
                        .clipShape(Capsule())
                }
                .disabled(isSubmitting)
            }
        }
        .sheet(isPresented: $displayTradeSuccessfulSheet) {
            SuccessfulTradeView(
                stockModel: stockModel,
                tradeSheet: self,
                stockDetailsView: stockDetailsView,
                allStocksSold: allStocksSold,
                viewModel: viewModel
            )
        }
        .toast(isShowing: $isShowingToast, text: toastMessage)
        .padding()
    }
}
