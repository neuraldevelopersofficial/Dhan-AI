class Stock {
  final String symbol;
  final String name;
  final double currentPrice;
  final double change;
  final double changePercent;
  final double volume;
  final String sector;
  final double? marketCap;

  Stock({
    required this.symbol,
    required this.name,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.sector,
    this.marketCap,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      currentPrice: (json['currentPrice'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      sector: json['sector'] as String,
      marketCap: json['marketCap'] != null
          ? (json['marketCap'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'currentPrice': currentPrice,
      'change': change,
      'changePercent': changePercent,
      'volume': volume,
      'sector': sector,
      'marketCap': marketCap,
    };
  }

  bool get isGainer => change > 0;
  bool get isLoser => change < 0;
}
