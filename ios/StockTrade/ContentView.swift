//
//  ContentView.swift
//  StockTrade
//

import SwiftUI
import Alamofire

struct RecentSearchItem: Codable, Identifiable, Equatable {
    let symbol: String
    let company: String

    var id: String { symbol }
}

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()

    @State private var stockSymbolOptions: [StockSymbolOption] = []
    @State private var searchTimer: Timer?
    @State private var isSearchPresented = false
    @State private var isSearchLoading = false
    @State private var latestSearchQuery = ""

    @State private var recentSearches: [RecentSearchItem] = []

    private let recentSearchesKey = "JoshiStocks.RecentSearches"
    private let maximumRecentSearches = 8
    private let quickPicks: [RecentSearchItem] = [
        RecentSearchItem(symbol: "AAPL", company: "Apple Inc."),
        RecentSearchItem(symbol: "MSFT", company: "Microsoft Corporation"),
        RecentSearchItem(symbol: "NVDA", company: "NVIDIA Corporation"),
        RecentSearchItem(symbol: "TSLA", company: "Tesla Inc."),
        RecentSearchItem(symbol: "AMZN", company: "Amazon.com Inc."),
        RecentSearchItem(symbol: "GOOGL", company: "Alphabet Inc.")
    ]

    // MARK: - Search

    private func fetchAutocompleteOptions(for query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            stockSymbolOptions = []
            isSearchLoading = false
            latestSearchQuery = ""
            return
        }

        latestSearchQuery = trimmed
        isSearchLoading = true

        APIClient.request("/api/v2/market/search/\(trimmed)")
            .responseDecodable(of: [StockSymbolOption].self) { response in

                DispatchQueue.main.async {
                    guard latestSearchQuery == trimmed else { return }

                    isSearchLoading = false

                    switch response.result {
                    case .success(let options):
                        stockSymbolOptions = Array(options.prefix(20))

                    case .failure(let error):
                        print("Search error: \(error.localizedDescription)")
                        stockSymbolOptions = []
                    }
                }
            }
    }

    private func debounceSearch() {
        searchTimer?.invalidate()

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            fetchAutocompleteOptions(for: viewModel.stock_ticker)
        }
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        guard
            let data = UserDefaults.standard.data(forKey: recentSearchesKey),
            let saved = try? JSONDecoder().decode([RecentSearchItem].self, from: data)
        else {
            return
        }

        recentSearches = saved
    }

    private func persistRecentSearches(_ searches: [RecentSearchItem]) {
        guard let data = try? JSONEncoder().encode(searches) else { return }

        UserDefaults.standard.set(data, forKey: recentSearchesKey)
    }

    private func rememberSearch(symbol: String, company: String) {
        let normalizedSymbol = symbol.uppercased()

        var updated = recentSearches.filter {
            $0.symbol.caseInsensitiveCompare(normalizedSymbol) != .orderedSame
        }

        updated.insert(
            RecentSearchItem(
                symbol: normalizedSymbol,
                company: company
            ),
            at: 0
        )

        updated = Array(updated.prefix(maximumRecentSearches))

        recentSearches = updated
        persistRecentSearches(updated)
    }

    private func deleteRecentSearches(at offsets: IndexSet) {
        var updated = recentSearches
        updated.remove(atOffsets: offsets)

        recentSearches = updated
        persistRecentSearches(updated)
    }

    private func clearRecentSearches() {
        recentSearches = []
        UserDefaults.standard.removeObject(forKey: recentSearchesKey)
    }

    // MARK: - Main Content

    private var mainContent: some View {
        Form {
            Section {
                Text(Date.now.formatted(date: .long, time: .omitted))
                    .font(.title)
                    .foregroundColor(.gray)
                    .bold()
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
            }

            PortfolioSection(viewModel: viewModel)
            ActivitySection(viewModel: viewModel)
            FavouritesSection(viewModel: viewModel)
            FooterSection()
        }
    }

    // MARK: - Recent Search UI

    private var recentSearchContent: some View {
        Group {
            if recentSearches.isEmpty {
                VStack(spacing: 0) {

                    VStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 34))
                            .foregroundColor(.secondary)

                        Text("No Recent Searches")
                            .font(.headline)

                        Text("Stocks you open will appear here.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 28)
                    .padding(.bottom, 18)

                    List {
                        Section("Quick Picks") {
                            ForEach(quickPicks) { item in
                                NavigationLink(
                                    destination:
                                        StockDetails(
                                            stock_ticker: item.symbol,
                                            viewModel: viewModel
                                        )
                                        .onAppear {
                                            rememberSearch(
                                                symbol: item.symbol,
                                                company: item.company
                                            )
                                        }
                                ) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.symbol)
                                            .font(.system(size: 20, weight: .semibold))

                                        Text(item.company)
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)

                        Spacer()

                        Button("Clear") {
                            clearRecentSearches()
                        }
                        .font(.subheadline)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    List {
                        ForEach(recentSearches) { item in
                            NavigationLink(
                                destination:
                                    StockDetails(
                                        stock_ticker: item.symbol,
                                        viewModel: viewModel
                                    )
                                    .onAppear {
                                        rememberSearch(
                                            symbol: item.symbol,
                                            company: item.company
                                        )
                                    }
                            ) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(item.symbol)
                                        .font(.system(size: 21, weight: .semibold))

                                    Text(item.company)
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 15))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .onDelete(perform: deleteRecentSearches)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        Group {
            if isSearchPresented {

                let trimmedQuery =
                    viewModel.stock_ticker
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                if trimmedQuery.isEmpty {

                    recentSearchContent

                } else if isSearchLoading {

                    VStack(spacing: 10) {
                        ProgressView()

                        Text("Searching…")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if !stockSymbolOptions.isEmpty {

                    List(stockSymbolOptions) { option in
                        NavigationLink(
                            destination:
                                StockDetails(
                                    stock_ticker: option.displaySymbol,
                                    viewModel: viewModel
                                )
                                .onAppear {
                                    rememberSearch(
                                        symbol: option.displaySymbol,
                                        company: option.description
                                    )
                                }
                        ) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(option.displaySymbol)
                                    .font(.system(size: 21, weight: .semibold))

                                Text(option.description)
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 15))
                                    .lineLimit(1)
                            }
                        }
                    }
                    .listStyle(.plain)

                } else {

                    ContentUnavailableView(
                        "No stocks found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another ticker or company name.")
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .zIndex(1)
    }

    // MARK: - View

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {

                if viewModel.isLoading {

                    ProgressView("Fetching Data...")

                } else {

                    if !isSearchPresented {
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
                loadRecentSearches()
                viewModel.fetchData()
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {

                    Button {
                        viewModel.fetchData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh portfolio")

                    EditButton()
                }
            }
            .searchable(
                text: $viewModel.stock_ticker,
                isPresented: $isSearchPresented,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search")
            )
            .onChange(of: viewModel.stock_ticker) { _, _ in
                debounceSearch()
            }
            .onChange(of: isSearchPresented) { _, presented in
                if !presented {
                    searchTimer?.invalidate()
                    stockSymbolOptions = []
                    isSearchLoading = false
                    latestSearchQuery = ""
                    viewModel.stock_ticker = ""
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
