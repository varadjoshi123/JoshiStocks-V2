const test = require("node:test");
const assert = require("node:assert/strict");
const { calculateBuy, calculateSell, positionMetrics } = require("../src/services/tradingMath");

test("buy uses only the new purchase amount when checking available cash", () => {
  const result = calculateBuy({
    position: { quantity: 10, total_cost: 1000 },
    quantity: 2,
    price: 100,
    cash: 250,
  });
  assert.equal(result.grossAmount, 200);
  assert.equal(result.newCash, 50);
  assert.equal(result.position.quantity, 12);
  assert.equal(result.position.total_cost, 1200);
});

test("buy rejects a purchase that exceeds available cash", () => {
  assert.throws(
    () => calculateBuy({ position: null, quantity: 3, price: 100, cash: 250 }),
    (error) => error.code === "INSUFFICIENT_FUNDS"
  );
});

test("partial sell removes average purchase cost, not current sale value", () => {
  const result = calculateSell({
    position: { quantity: 10, total_cost: 1000 },
    quantity: 5,
    price: 150,
    cash: 500,
  });
  assert.equal(result.grossAmount, 750);
  assert.equal(result.costRemoved, 500);
  assert.equal(result.realizedPnl, 250);
  assert.equal(result.position.quantity, 5);
  assert.equal(result.position.total_cost, 500);
  assert.equal(result.newCash, 1250);
});

test("selling an entire position zeroes the cost basis", () => {
  const result = calculateSell({
    position: { quantity: 4, total_cost: 320 },
    quantity: 4,
    price: 90,
    cash: 1000,
  });
  assert.equal(result.position.quantity, 0);
  assert.equal(result.position.total_cost, 0);
  assert.equal(result.realizedPnl, 40);
});

test("sell rejects overselling", () => {
  assert.throws(
    () => calculateSell({ position: { quantity: 2, total_cost: 100 }, quantity: 3, price: 60, cash: 0 }),
    (error) => error.code === "INSUFFICIENT_SHARES"
  );
});

test("portfolio metrics calculate market value and return correctly", () => {
  const metrics = positionMetrics({ quantity: 10, totalCost: 1000, currentPrice: 125 });
  assert.equal(metrics.marketValue, 1250);
  assert.equal(metrics.unrealizedPnl, 250);
  assert.equal(metrics.unrealizedPnlPercent, 0.25);
  assert.equal(metrics.averageCost, 100);
});
