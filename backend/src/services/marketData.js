const { TTLCache } = require("../lib/cache");

class UpstreamError extends Error {
  constructor(message, status = 502) {
    super(message);
    this.name = "UpstreamError";
    this.status = status;
  }
}

function ymd(date) {
  return date.toISOString().slice(0, 10);
}

class MarketDataService {
  constructor({ finnhubApiKey, polygonApiKey, fetchImpl = fetch }) {
    this.finnhubApiKey = finnhubApiKey;
    this.polygonApiKey = polygonApiKey;
    this.fetchImpl = fetchImpl;
    this.cache = new TTLCache();
  }

  async json(url, { cacheKey, ttlMs = 0, staleIfError = true } = {}) {
    if (cacheKey) {
      const cached = this.cache.get(cacheKey);
      if (cached !== undefined) return cached;
    }

    try {
      const response = await this.fetchImpl(url, {
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(10000),
      });
      if (!response.ok) {
        throw new UpstreamError(`Market-data provider returned HTTP ${response.status}`);
      }
      const data = await response.json();
      if (data === null || data === undefined) {
        throw new UpstreamError("Market-data provider returned an empty response");
      }
      if (cacheKey && ttlMs > 0) this.cache.set(cacheKey, data, ttlMs);
      return data;
    } catch (error) {
      if (cacheKey && staleIfError) {
        const stale = this.cache.get(cacheKey, { allowStale: true });
        if (stale !== undefined) return stale;
      }
      throw error;
    }
  }

  finnhub(path, params = {}) {
    const search = new URLSearchParams({ ...params, token: this.finnhubApiKey });
    return `https://finnhub.io/api/v1/${path}?${search.toString()}`;
  }

  async search(query) {
    const data = await this.json(this.finnhub("search", { q: query }), {
      cacheKey: `search:${query.toUpperCase()}`,
      ttlMs: 5 * 60 * 1000,
    });
    return (data.result || []).filter(
      (item) => item.type === "Common Stock" && !String(item.symbol || "").includes(".")
    );
  }

  profile(ticker) {
    return this.json(this.finnhub("stock/profile2", { symbol: ticker }), {
      cacheKey: `profile:${ticker}`,
      ttlMs: 24 * 60 * 60 * 1000,
    });
  }

  quote(ticker) {
    return this.json(this.finnhub("quote", { symbol: ticker }), {
      cacheKey: `quote:${ticker}`,
      ttlMs: 15 * 1000,
    });
  }

  peers(ticker) {
    return this.json(this.finnhub("stock/peers", { symbol: ticker }), {
      cacheKey: `peers:${ticker}`,
      ttlMs: 12 * 60 * 60 * 1000,
    });
  }

  recommendation(ticker) {
    return this.json(this.finnhub("stock/recommendation", { symbol: ticker }), {
      cacheKey: `recommendation:${ticker}`,
      ttlMs: 6 * 60 * 60 * 1000,
    });
  }

  insiderSentiment(ticker) {
    return this.json(
      this.finnhub("stock/insider-sentiment", { symbol: ticker, from: "2022-01-01" }),
      { cacheKey: `sentiment:${ticker}`, ttlMs: 6 * 60 * 60 * 1000 }
    );
  }

  async earnings(ticker) {
    const data = await this.json(this.finnhub("stock/earnings", { symbol: ticker }), {
      cacheKey: `earnings:${ticker}`,
      ttlMs: 6 * 60 * 60 * 1000,
    });
    return Array.isArray(data)
      ? data.map((row) => Object.fromEntries(Object.entries(row).map(([k, v]) => [k, v ?? 0])))
      : data;
  }

  news(ticker) {
    const to = new Date();
    const from = new Date(to);
    from.setDate(from.getDate() - 8);
    return this.json(
      this.finnhub("company-news", { symbol: ticker, from: ymd(from), to: ymd(to) }),
      { cacheKey: `news:${ticker}:${ymd(to)}`, ttlMs: 15 * 60 * 1000 }
    ).then((items) =>
      (Array.isArray(items) ? items : []).filter(
        (n) => n.headline?.trim() && n.url?.trim() && n.image?.trim()
      )
    );
  }

  polygonAggregates(ticker, multiplier, timespan, from, to, ttlMs) {
    const url = `https://api.polygon.io/v2/aggs/ticker/${encodeURIComponent(ticker)}/range/${multiplier}/${timespan}/${ymd(from)}/${ymd(to)}?adjusted=true&sort=asc&apiKey=${encodeURIComponent(this.polygonApiKey)}`;
    return this.json(url, {
      cacheKey: `polygon:${ticker}:${multiplier}:${timespan}:${ymd(from)}:${ymd(to)}`,
      ttlMs,
    });
  }

  historical(ticker) {
    const to = new Date();
    const from = new Date(to);
    from.setFullYear(from.getFullYear() - 2);
    return this.polygonAggregates(ticker, 1, "day", from, to, 6 * 60 * 60 * 1000);
  }

  hourly(ticker) {
    const to = new Date();
    const from = new Date(to);
    from.setDate(from.getDate() - 7);
    return this.polygonAggregates(ticker, 1, "hour", from, to, 5 * 60 * 1000);
  }
}

module.exports = { MarketDataService, UpstreamError };
