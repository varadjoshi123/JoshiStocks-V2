//
//  ContentView.swift
//  StockTrade
//
//  Created by Gaurav Baisware on 4/8/24.
//

import SwiftUI
import Alamofire
import SwiftyJSON

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @State private var stockSymbolOptions: [StockSymbolOption] = []
    @State private var searchTimer: Timer?
    @State private var isSearchActive: Bool = false
    @State private var isSearchLoading: Bool = false
    @State private var latestSearchQuery: String = ""
    
    func fetchAutocompleteOptions(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            stockSymbolOptions = []
            isSearchLoading = false
            latestSearchQuery = ""
            return
        }

        latestSearchQuery = trimmed
        isSearchLoading = true

        APIClient.request("/api/v2/market/search/\(trimmed)").responseDecodable(of: [StockSymbolOption].self) { response in
            DispatchQueue.main.async {
                guard self.latestSearchQuery == trimmed else { return }
                self.isSearchLoading = false
                switch response.result {
                case .success(let options):
                    self.stockSymbolOptions = Array(options.prefix(20))
                case .failure(let error):
                    print("Search error: \(error.localizedDescription)")
                    self.stockSymbolOptions = []
                }
            }
        }
    }

    private var mainContent: some View{
        Form {
            Section {
                Text(Date.now.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .foregroundColor(Color.gray)
                    .bold()
                    .padding(.horizontal, 2.0)
                    .padding(.vertical, 4.0)
            }
            PortfolioSection(viewModel: self.viewModel)
            ActivitySection(viewModel: self.viewModel)
            FavouritesSection(viewModel: self.viewModel)
            FooterSection()
        }
    }
    
    private var searchResults: some View {
        Group {
            if isSearchActive {
                if isSearchLoading {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Searching…")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.background)
                } else if !stockSymbolOptions.isEmpty {
                    List($stockSymbolOptions, id: \.id) { option in
                        NavigationLink(destination: StockDetails(stock_ticker: option.displaySymbol.wrappedValue, viewModel: self.viewModel)) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.displaySymbol.wrappedValue)
                                    .font(.system(size: 21, weight: .semibold))
                                Text(option.description.wrappedValue)
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .background(Color.white.opacity(0.9))
                } else if !viewModel.stock_ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView(
                        "No stocks found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another ticker or company name.")
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .zIndex(1)
    }

    private func debounceSearch() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            self.fetchAutocompleteOptions(for: self.viewModel.stock_ticker)
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                if viewModel.isLoading {
                    ProgressView("Fetching Data...")
                } else {
                    if !self.isSearchActive {
                        VStack(spacing: 0) {
                            if let errorMessage = viewModel.errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal)
                                    .padding(.vertical, 6)
                            }
                            mainContent
                        }
                    }
                    searchResults
                }
            }
            .navigationTitle("JoshiStocks")
            .onAppear {
                viewModel.fetchData()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.fetchData() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh portfolio")
                    EditButton()
                }
            }
            .searchable(text: $viewModel.stock_ticker, placement: .navigationBarDrawer(displayMode: .always)) {
                EmptyView()
            }
            .onChange(of: viewModel.stock_ticker) { _, newValue in
                self.isSearchActive = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                debounceSearch()
            }
        }
    }
}

#Preview {
    ContentView()
}
