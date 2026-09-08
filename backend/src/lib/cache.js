class TTLCache {
  constructor() {
    this.items = new Map();
  }

  get(key, { allowStale = false } = {}) {
    const item = this.items.get(key);
    if (!item) return undefined;
    if (item.expiresAt > Date.now()) return item.value;
    if (allowStale) return item.value;
    this.items.delete(key);
    return undefined;
  }

  set(key, value, ttlMs) {
    this.items.set(key, {
      value,
      expiresAt: Date.now() + ttlMs,
    });
    return value;
  }

  delete(key) {
    this.items.delete(key);
  }

  clear() {
    this.items.clear();
  }
}

module.exports = { TTLCache };
