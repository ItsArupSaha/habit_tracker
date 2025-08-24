import 'package:flutter/material.dart';
import '../models/quote.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback onFavorite;
  final VoidCallback onCopy;
  
  const QuoteCard({
    super.key,
    required this.quote,
    required this.onFavorite,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Card(
      elevation: isDark ? 8 : 4,
      shadowColor: isDark 
          ? Colors.black.withOpacity(0.4)
          : Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark 
              ? const Color(0xFFFF6B35).withOpacity(0.6)
              : Colors.grey.withOpacity(0.2),
          width: isDark ? 1.5 : 1,
        ),
      ),
      color: isDark 
          ? const Color(0xFF1E2337) 
          : const Color(0xFFFFE0B2),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote text
            Text(
              '"${quote.text}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.4,
                color: isDark 
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.left,
            ),
            
            const SizedBox(height: 16),
            
            // Author and actions row
            Row(
              children: [
                // Author
                Expanded(
                  child: Text(
                    '— ${quote.author}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark 
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2A3149)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.copy_outlined,
                          size: 20,
                          color: isDark 
                              ? const Color(0xFF9CA3AF)
                              : Colors.grey[600],
                        ),
                        onPressed: onCopy,
                        tooltip: 'Copy quote',
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Favorite button
                    Container(
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF2A3149)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          quote.isFavorite 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          size: 20,
                          color: quote.isFavorite 
                              ? Colors.red 
                              : (isDark 
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.grey[600]),
                        ),
                        onPressed: onFavorite,
                        tooltip: quote.isFavorite 
                            ? 'Remove from favorites' 
                            : 'Add to favorites',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
