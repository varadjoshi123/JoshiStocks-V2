function roundMoney(value) {
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function assertPositiveInteger(quantity) {
  if (!Number.isInteger(quantity) || quantity <= 0) {
    const error = new Error("Quantity must be a positive whole number");
    error.code = "INVALID_QUANTITY";
    throw error;
  }
}

function calculateBuy({ position, quantity, price, cash }) {
  assertPositiveInteger(quantity);
  if (!Number.isFinite(price) || price <= 0) {
    const error = new Error("A valid market price is required");
    error.code = "INVALID_PRICE";
    throw error;
  }

  const grossAmount = roundMoney(price * quantity);
  if (grossAmount > cash + 0.000001) {
    const error = new Error("Not enough cash to complete this purchase");
    error.code = "INSUFFICIENT_FUNDS";
    throw error;
  }

  const oldQuantity = Number(position?.quantity || 0);
  const oldCost = Number(position?.total_cost || 0);
  const newQuantity = oldQuantity + quantity;
  const newCost = roundMoney(oldCost + grossAmount);

  return {
    grossAmount,
    newCash: roundMoney(cash - grossAmount),
    position: {
      quantity: newQuantity,
      total_cost: newCost,
      average_cost: newQuantity > 0 ? newCost / newQuantity : 0,
    },
  };
}

function calculateSell({ position, quantity, price, cash }) {
  assertPositiveInteger(quantity);
  if (!Number.isFinite(price) || price <= 0) {
    const error = new Error("A valid market price is required");
    error.code = "INVALID_PRICE";
    throw error;
  }

  const heldQuantity = Number(position?.quantity || 0);
  const totalCost = Number(position?.total_cost || 0);
  if (!position || heldQuantity < quantity) {
    const error = new Error("Not enough shares to complete this sale");
    error.code = "INSUFFICIENT_SHARES";
    throw error;
  }

  const averageCost = heldQuantity > 0 ? totalCost / heldQuantity : 0;
  const grossAmount = roundMoney(price * quantity);
  const costRemoved = roundMoney(averageCost * quantity);
  const realizedPnl = roundMoney(grossAmount - costRemoved);
  const newQuantity = heldQuantity - quantity;
  const newCost = newQuantity === 0 ? 0 : roundMoney(totalCost - costRemoved);

  return {
    grossAmount,
    costRemoved,
    realizedPnl,
    newCash: roundMoney(cash + grossAmount),
    position: {
      quantity: newQuantity,
      total_cost: newCost,
      average_cost: newQuantity > 0 ? newCost / newQuantity : 0,
    },
  };
}

function positionMetrics({ quantity, totalCost, currentPrice }) {
  const marketValue = roundMoney(quantity * currentPrice);
  const unrealizedPnl = roundMoney(marketValue - totalCost);
  const unrealizedPnlPercent = totalCost > 0 ? unrealizedPnl / totalCost : 0;
  return {
    marketValue,
    unrealizedPnl,
    unrealizedPnlPercent,
    averageCost: quantity > 0 ? totalCost / quantity : 0,
  };
}

module.exports = {
  calculateBuy,
  calculateSell,
  positionMetrics,
  roundMoney,
};
