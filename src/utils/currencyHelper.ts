export function formatCurrency(amount: number, symbol: string = '¥'): string {
  if (amount === 0) return `${symbol}0.00`;
  if (amount >= 10000) {
    return `${symbol}${(amount / 10000).toFixed(2)}万`;
  }
  return `${symbol}${amount.toFixed(2)}`;
}

export function formatCurrencyFull(amount: number, symbol: string = '¥'): string {
  return `${symbol}${amount.toFixed(2)}`;
}

export function calculateDailyCost(price: number, daysSincePurchase: number): number {
  if (daysSincePurchase <= 0) return price;
  return price / daysSincePurchase;
}
