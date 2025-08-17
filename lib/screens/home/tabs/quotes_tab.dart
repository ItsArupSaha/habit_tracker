import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../../services/auth_service.dart';
import '../../../services/quotes_service.dart';
import '../../../models/quote.dart';
import '../../../widgets/quote_card.dart';

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
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshQuotes,
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
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.format_quote_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No quotes available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull down to refresh and get new quotes',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
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
