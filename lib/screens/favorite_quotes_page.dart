import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/quotes_service.dart';
import '../models/quote.dart';
import '../widgets/quote_card.dart';

class FavoriteQuotesPage extends StatefulWidget {
  const FavoriteQuotesPage({super.key});

  @override
  State<FavoriteQuotesPage> createState() => _FavoriteQuotesPageState();
}

class _FavoriteQuotesPageState extends State<FavoriteQuotesPage> {
  final QuotesService _quotesService = QuotesService();
  List<Quote> _favoriteQuotes = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadFavoriteQuotes();
  }
  
  Future<void> _loadFavoriteQuotes() async {
    setState(() => _isLoading = true);
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser != null) {
        final favorites = await _quotesService.getFavoriteQuotes();
        setState(() {
          _favoriteQuotes = favorites;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorite quotes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark 
          ? const Color(0xFF0A0E21) 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark 
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF2C3E50),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Favorite Quotes',
          style: TextStyle(
            color: isDark 
                ? const Color(0xFFE5E7EB)
                : const Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFFF6B35),
              ),
            )
          : _favoriteQuotes.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteQuotes.length,
                  itemBuilder: (context, index) {
                    final quote = _favoriteQuotes[index];
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
              Icons.favorite_border,
              size: 60,
              color: isDark 
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorite quotes yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: isDark 
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFF2C3E50),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start adding quotes to your favorites!',
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
            content: Text('Please login to manage favorite quotes'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      await _quotesService.removeFavorite(quote.id);
      setState(() {
        _favoriteQuotes.removeWhere((q) => q.id == quote.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quote removed from favorites')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove favorite: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _copyQuote(Quote quote) {
    Clipboard.setData(ClipboardData(text: '${quote.text} — ${quote.author}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied to clipboard!')),
    );
  }
}
