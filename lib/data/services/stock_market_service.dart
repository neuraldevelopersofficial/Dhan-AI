import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to fetch real-time Indian stock market data
/// Uses Yahoo Finance API (free) for real-time data
class StockMarketService {
  // Cache to avoid repeated API calls (5 minutes cache)
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  // Popular NSE stocks to fetch
  static const List<String> _popularNseStocks = [
    'RELIANCE', 'TCS', 'HDFCBANK', 'INFY', 'ICICIBANK',
    'BHARTIARTL', 'HINDUNILVR', 'SBIN', 'LT', 'AXISBANK',
    'MARUTI', 'ITC', 'ASIANPAINT', 'KOTAKBANK', 'HCLTECH',
    'WIPRO', 'ULTRACEMCO', 'NESTLEIND', 'TITAN', 'BAJFINANCE',
    'ONGC', 'NTPC', 'POWERGRID', 'COALINDIA', 'BPCL',
    'TATAMOTORS', 'M&M', 'HEROMOTOCO', 'BAJAJFINSV', 'INDUSINDBK',
  ];
  
  /// Fetch top gainers of the day from Indian stock market (real-time)
  /// Returns list of stocks sorted by gain percentage
  static Future<List<Stock>> getTopGainers({int limit = 20}) async {
    try {
      // Check cache first
      final cacheKey = 'top_gainers_$limit';
      final cached = _cache[cacheKey];
      if (cached != null && 
          DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        print('Returning cached top gainers');
        return cached.data;
      }
      
      print('Fetching real-time stock data from Yahoo Finance...');
      
      // Fetch real-time data from Yahoo Finance
      final stocks = await _fetchRealTimeStocks();
      
      // Sort by change percentage (descending) to get top gainers
      stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
      
      final topGainers = stocks.where((s) => s.changePercent > 0).take(limit).toList();
      
      // Update cache
      _cache[cacheKey] = _CacheEntry(DateTime.now(), topGainers);
      
      return topGainers;
    } catch (e) {
      print('Error fetching real-time top gainers: $e');
      // Try fallback API or return empty list
      try {
        return await _fetchWithAlphaVantage(limit);
      } catch (fallbackError) {
        print('Fallback API also failed: $fallbackError');
        // Return empty list instead of mock data
        return [];
      }
    }
  }
  
  /// Fetch real-time stock data using multiple API sources for reliability
  static Future<List<Stock>> _fetchRealTimeStocks() async {
    final stocks = <Stock>[];
    
    print('Starting to fetch ${_popularNseStocks.length} stocks...');
    
    // Try fetching in smaller batches using multiple symbols per request
    final batchSize = 5; // Smaller batches for better reliability
    for (int i = 0; i < _popularNseStocks.length; i += batchSize) {
      final batch = _popularNseStocks.skip(i).take(batchSize).toList();
      final symbols = batch.map((s) => '$s.NS').join(',');
      
      try {
        // Use Yahoo Finance API with better format
        final url = Uri.parse(
          'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$symbols',
        );
        
        print('Fetching batch: ${batch.join(", ")}');
        
        final response = await http.get(
          url,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': '*/*',
            'Accept-Language': 'en-US,en;q=0.9',
            'Origin': 'https://finance.yahoo.com',
            'Referer': 'https://finance.yahoo.com/',
          },
        ).timeout(const Duration(seconds: 15));
        
        print('Response status for batch: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          try {
            final responseBody = response.body;
            if (responseBody.isEmpty) {
              print('Empty response body for batch');
              continue;
            }
            
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            final quotes = data['quoteResponse']?['result'] as List?;
            
            print('Found ${quotes?.length ?? 0} quotes in batch');
            
            if (quotes != null && quotes.isNotEmpty) {
              for (final quote in quotes) {
                try {
                  final quoteMap = quote as Map<String, dynamic>;
                  final symbolRaw = quoteMap['symbol'] as String? ?? '';
                  final symbol = symbolRaw.replaceAll('.NS', '').replaceAll('.BO', '');
                  
                  if (symbol.isEmpty) continue;
                  
                  final name = quoteMap['longName'] as String? ?? 
                              quoteMap['shortName'] as String? ?? 
                              symbol;
                  
                  // Get current price - try multiple fields
                  var currentPrice = (quoteMap['regularMarketPrice'] as num?)?.toDouble();
                  if (currentPrice == null || currentPrice == 0) {
                    currentPrice = (quoteMap['previousClose'] as num?)?.toDouble();
                  }
                  if (currentPrice == null || currentPrice == 0) {
                    currentPrice = (quoteMap['regularMarketPreviousClose'] as num?)?.toDouble();
                  }
                  
                  // Get previous close
                  var previousClose = (quoteMap['regularMarketPreviousClose'] as num?)?.toDouble();
                  if (previousClose == null || previousClose == 0) {
                    previousClose = (quoteMap['previousClose'] as num?)?.toDouble();
                  }
                  
                  // Skip if no valid price
                  if (currentPrice == null || currentPrice == 0) {
                    print('No valid price for $symbol');
                    continue;
                  }
                  
                  // Calculate change and percentage
                  double change = 0.0;
                  double changePercent = 0.0;
                  
                  // Try to get from API first
                  final apiChange = quoteMap['regularMarketChange'] as num?;
                  final apiChangePercent = quoteMap['regularMarketChangePercent'] as num?;
                  
                  if (apiChange != null && apiChangePercent != null) {
                    change = apiChange.toDouble();
                    changePercent = apiChangePercent.toDouble();
                  } else if (previousClose != null && previousClose > 0) {
                    // Calculate manually
                    change = currentPrice - previousClose;
                    changePercent = (change / previousClose) * 100;
                  }
                  
                  final volume = (quoteMap['regularMarketVolume'] as num?)?.toDouble() ?? 
                                (quoteMap['volume'] as num?)?.toDouble() ?? 0.0;
                  
                  print('✓ $symbol: ₹${currentPrice.toStringAsFixed(2)} (${changePercent > 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%)');
                  
                  stocks.add(Stock(
                    symbol: symbol,
                    name: name,
                    currentPrice: currentPrice,
                    change: change,
                    changePercent: changePercent,
                    volume: volume,
                    sector: _getSectorFromSymbol(symbol),
                    marketCap: null,
                  ));
                } catch (e) {
                  print('Error parsing quote: $e');
                  continue;
                }
              }
            }
          } catch (e) {
            print('Error parsing response for batch: $e');
            print('Response body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
          }
        } else {
          print('Failed to fetch batch. Status: ${response.statusCode}');
          print('Response: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        }
      } catch (e) {
        print('Error fetching batch ${batch.join(", ")}: $e');
        continue;
      }
      
      // Delay between batches
      if (i + batchSize < _popularNseStocks.length) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
    
    print('Successfully fetched ${stocks.length} stocks');
    return stocks;
  }
  
  /// Fallback to Alpha Vantage API if Yahoo Finance fails
  static Future<List<Stock>> _fetchWithAlphaVantage(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('alpha_vantage_api_key');
    
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Alpha Vantage API key not configured');
    }
    
    // Alpha Vantage doesn't have a top gainers endpoint for Indian stocks
    // So we'll just return empty list and let the UI handle it
    return [];
  }
  
  /// Get sector information based on stock symbol
  static String _getSectorFromSymbol(String symbol) {
    final sectorMap = {
      'RELIANCE': 'Oil & Gas',
      'TCS': 'IT Services',
      'INFY': 'IT Services',
      'WIPRO': 'IT Services',
      'HCLTECH': 'IT Services',
      'HDFCBANK': 'Banking',
      'ICICIBANK': 'Banking',
      'SBIN': 'Banking',
      'AXISBANK': 'Banking',
      'KOTAKBANK': 'Banking',
      'INDUSINDBK': 'Banking',
      'BHARTIARTL': 'Telecom',
      'HINDUNILVR': 'FMCG',
      'ITC': 'FMCG',
      'NESTLEIND': 'FMCG',
      'LT': 'Engineering',
      'MARUTI': 'Automobile',
      'TATAMOTORS': 'Automobile',
      'M&M': 'Automobile',
      'HEROMOTOCO': 'Automobile',
      'ASIANPAINT': 'Paints',
      'ULTRACEMCO': 'Cement',
      'TITAN': 'Consumer Goods',
      'BAJFINANCE': 'Financial Services',
      'BAJAJFINSV': 'Financial Services',
      'ONGC': 'Oil & Gas',
      'NTPC': 'Power',
      'POWERGRID': 'Power',
      'COALINDIA': 'Mining',
      'BPCL': 'Oil & Gas',
    };
    
    return sectorMap[symbol] ?? 'Others';
  }

  /// Get mock top gainers for Indian stock market (kept as fallback, not currently used)
  @Deprecated('Using real-time data from Yahoo Finance API')
  // ignore: unused_element
  static List<Stock> _getMockTopGainers(int limit) {
    // Popular Indian stocks with realistic mock data
    final stocks = <Stock>[
      Stock(
        symbol: 'RELIANCE',
        name: 'Reliance Industries Ltd',
        currentPrice: 2456.75,
        change: 125.50,
        changePercent: 5.38,
        volume: 15234567,
        sector: 'Oil & Gas',
        marketCap: 16500000000000,
      ),
      Stock(
        symbol: 'TCS',
        name: 'Tata Consultancy Services',
        currentPrice: 3456.80,
        change: 145.30,
        changePercent: 4.39,
        volume: 8765432,
        sector: 'IT Services',
        marketCap: 12500000000000,
      ),
      Stock(
        symbol: 'HDFCBANK',
        name: 'HDFC Bank Ltd',
        currentPrice: 1645.25,
        change: 68.50,
        changePercent: 4.34,
        volume: 12345678,
        sector: 'Banking',
        marketCap: 12500000000000,
      ),
      Stock(
        symbol: 'INFY',
        name: 'Infosys Ltd',
        currentPrice: 1456.90,
        change: 52.30,
        changePercent: 3.72,
        volume: 9876543,
        sector: 'IT Services',
        marketCap: 6000000000000,
      ),
      Stock(
        symbol: 'ICICIBANK',
        name: 'ICICI Bank Ltd',
        currentPrice: 956.75,
        change: 32.45,
        changePercent: 3.51,
        volume: 11234567,
        sector: 'Banking',
        marketCap: 6700000000000,
      ),
      Stock(
        symbol: 'BHARTIARTL',
        name: 'Bharti Airtel Ltd',
        currentPrice: 1125.50,
        change: 38.75,
        changePercent: 3.56,
        volume: 7654321,
        sector: 'Telecom',
        marketCap: 6200000000000,
      ),
      Stock(
        symbol: 'HINDUNILVR',
        name: 'Hindustan Unilever Ltd',
        currentPrice: 2456.25,
        change: 78.50,
        changePercent: 3.30,
        volume: 5432109,
        sector: 'FMCG',
        marketCap: 5600000000000,
      ),
      Stock(
        symbol: 'SBIN',
        name: 'State Bank of India',
        currentPrice: 645.80,
        change: 21.35,
        changePercent: 3.42,
        volume: 19876543,
        sector: 'Banking',
        marketCap: 5750000000000,
      ),
      Stock(
        symbol: 'LT',
        name: 'Larsen & Toubro Ltd',
        currentPrice: 3256.40,
        change: 102.80,
        changePercent: 3.26,
        volume: 8765432,
        sector: 'Engineering',
        marketCap: 4600000000000,
      ),
      Stock(
        symbol: 'AXISBANK',
        name: 'Axis Bank Ltd',
        currentPrice: 1125.60,
        change: 35.25,
        changePercent: 3.23,
        volume: 7654321,
        sector: 'Banking',
        marketCap: 3400000000000,
      ),
      Stock(
        symbol: 'MARUTI',
        name: 'Maruti Suzuki India Ltd',
        currentPrice: 9876.50,
        change: 286.75,
        changePercent: 2.99,
        volume: 6543210,
        sector: 'Automobile',
        marketCap: 2980000000000,
      ),
      Stock(
        symbol: 'ITC',
        name: 'ITC Ltd',
        currentPrice: 456.75,
        change: 12.35,
        changePercent: 2.78,
        volume: 10987654,
        sector: 'FMCG',
        marketCap: 5650000000000,
      ),
      Stock(
        symbol: 'ASIANPAINT',
        name: 'Asian Paints Ltd',
        currentPrice: 3245.60,
        change: 78.90,
        changePercent: 2.49,
        volume: 4321098,
        sector: 'Paints',
        marketCap: 3100000000000,
      ),
      Stock(
        symbol: 'KOTAKBANK',
        name: 'Kotak Mahindra Bank',
        currentPrice: 1876.25,
        change: 42.80,
        changePercent: 2.33,
        volume: 3210987,
        sector: 'Banking',
        marketCap: 3700000000000,
      ),
      Stock(
        symbol: 'HCLTECH',
        name: 'HCL Technologies Ltd',
        currentPrice: 1245.80,
        change: 26.45,
        changePercent: 2.17,
        volume: 8765432,
        sector: 'IT Services',
        marketCap: 3400000000000,
      ),
    ];

    // Sort by change percentage (descending) and return top N
    stocks.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    return stocks.take(limit).toList();
  }

  /// Fetch stock data by symbol (real-time)
  static Future<Stock?> getStockBySymbol(String symbol) async {
    try {
      // Check cache first
      final cacheKey = 'stock_$symbol';
      final cached = _cache[cacheKey];
      if (cached != null && 
          DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        if (cached.data.isNotEmpty) {
          return cached.data.first;
        }
      }
      
      // Fetch real-time data using same format as batch fetching
      final symbolUpper = symbol.toUpperCase();
      final nseSymbol = '$symbolUpper.NS';
      
      final url = Uri.parse(
        'https://query1.finance.yahoo.com/v7/finance/quote?symbols=$nseSymbol&fields=symbol,shortName,longName,regularMarketPrice,regularMarketPreviousClose,regularMarketChange,regularMarketChangePercent,regularMarketVolume',
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
          'Referer': 'https://finance.yahoo.com',
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final quotes = data['quoteResponse']?['result'] as List?;
        
        if (quotes != null && quotes.isNotEmpty) {
          final quote = quotes[0];
          try {
            final symbolRaw = quote['symbol'] as String? ?? '';
            final stockSymbol = symbolRaw.replaceAll('.NS', '');
            final name = quote['longName'] as String? ?? 
                        quote['shortName'] as String? ?? 
                        stockSymbol;
            
            // Get prices - use regularMarketPrice for current, regularMarketPreviousClose for previous
            final currentPrice = (quote['regularMarketPrice'] as num?)?.toDouble();
            final previousClose = (quote['regularMarketPreviousClose'] as num?)?.toDouble();
            
            // Use current price, fallback to previous close
            final price = currentPrice ?? previousClose ?? 0.0;
            
            if (price > 0 && stockSymbol.isNotEmpty) {
              // Calculate change if not provided
              final change = quote['regularMarketChange'] as num?;
              final changePercent = quote['regularMarketChangePercent'] as num?;
              
              double actualChange = 0.0;
              double actualChangePercent = 0.0;
              
              if (change != null && changePercent != null) {
                actualChange = change.toDouble();
                actualChangePercent = changePercent.toDouble();
              } else if (previousClose != null && previousClose > 0 && currentPrice != null) {
                actualChange = currentPrice - previousClose;
                actualChangePercent = (actualChange / previousClose) * 100;
              }
              
              final volume = (quote['regularMarketVolume'] as num?)?.toDouble() ?? 0.0;
              
              final stock = Stock(
                symbol: stockSymbol,
                name: name,
                currentPrice: price,
                change: actualChange,
                changePercent: actualChangePercent,
                volume: volume,
                sector: _getSectorFromSymbol(stockSymbol),
                marketCap: null,
              );
              
              // Update cache
              _cache[cacheKey] = _CacheEntry(DateTime.now(), [stock]);
              
              return stock;
            }
          } catch (e) {
            print('Error parsing stock quote for $symbol: $e');
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error fetching stock by symbol: $e');
      return null;
    }
  }

  /// Format market cap for display
  static String formatMarketCap(double? marketCap) {
    if (marketCap == null) return 'N/A';
    if (marketCap >= 1000000000000) {
      return '₹${(marketCap / 1000000000000).toStringAsFixed(2)}T';
    } else if (marketCap >= 10000000000) {
      return '₹${(marketCap / 10000000000).toStringAsFixed(2)}K Cr';
    } else if (marketCap >= 10000000) {
      return '₹${(marketCap / 10000000).toStringAsFixed(2)}Cr';
    }
    return '₹${marketCap.toStringAsFixed(2)}';
  }

  /// Format volume for display
  static String formatVolume(double volume) {
    if (volume >= 10000000) {
      return '${(volume / 10000000).toStringAsFixed(2)}Cr';
    } else if (volume >= 100000) {
      return '${(volume / 100000).toStringAsFixed(2)}L';
    }
    return volume.toStringAsFixed(0);
  }
  
  /// Clear cache (useful for manual refresh)
  static void clearCache() {
    _cache.clear();
    print('Stock market cache cleared');
  }
}

/// Cache entry for stock data
class _CacheEntry {
  final DateTime timestamp;
  final List<Stock> data;
  
  _CacheEntry(this.timestamp, this.data);
}
