import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../services/auth_service.dart';
import '../../../services/quotes_service.dart';
import '../../../models/quote.dart';
import '../../../widgets/quote_card.dart';
import '../../../screens/favorite_quotes_page.dart';

class QuotesTab extends StatefulWidget {
  const QuotesTab({super.key});

  @override
  State<QuotesTab> createState() => _QuotesTabState();
}

class _QuotesTabState extends State<QuotesTab> {
  final QuotesService _quotesService = QuotesService();
  List<Quote> _quotes = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }
  
  Future<void> _loadQuotes() async {
    if (!_isRefreshing) {
      setState(() => _isLoading = true);
    }
    
    try {
      final quotes = await _quotesService.getRandomQuotes(count: 10);
      setState(() {
        _quotes = quotes;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load quotes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshQuotes() async {
    setState(() => _isRefreshing = true);
    await _loadQuotes();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0A0E21) 
          : const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header with favorites button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Quotes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark 
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF2C3E50),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1E2337) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark 
                          ? const Color(0xFF2A3149)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: const Color(0xFFFF6B35),
                          size: 24,
                        ),
                        if (_quotes.where((q) => q.isFavorite).isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '${_quotes.where((q) => q.isFavorite).length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const FavoriteQuotesPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Quotes list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFFFF6B35),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshQuotes,
                    color: const Color(0xFFFF6B35),
                    child: _quotes.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _quotes.length,
                            itemBuilder: (context, index) {
                              final quote = _quotes[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: QuoteCard(
                                  quote: quote,
                                  onFavorite: () => _toggleFavorite(quote),
                                  onCopy: () => _copyQuote(quote),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E2337) 
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: isDark 
                    ? const Color(0xFF2A3149)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.format_quote_outlined,
              size: 60,
              color: isDark 
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No quotes available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark 
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pull down to refresh and get new quotes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark 
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _toggleFavorite(Quote quote) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to save favorite quotes'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      if (quote.isFavorite) {
        await _quotesService.removeFavorite(quote.id);
        setState(() {
          final index = _quotes.indexWhere((q) => q.id == quote.id);
          if (index != -1) {
            _quotes[index] = quote.copyWith(isFavorite: false);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote removed from favorites')),
          );
        }
      } else {
        await _quotesService.addToFavorites(quote);
        setState(() {
          final index = _quotes.indexWhere((q) => q.id == quote.id);
          if (index != -1) {
            _quotes[index] = quote.copyWith(isFavorite: true);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quote added to favorites!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _copyQuote(Quote quote) {
    // Copy quote text to clipboard
    Clipboard.setData(ClipboardData(text: '${quote.text} — ${quote.author}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied to clipboard!')),
    );
  }
}
