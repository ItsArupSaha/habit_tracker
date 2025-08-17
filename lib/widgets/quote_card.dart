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
    return Card(
      elevation: 2,
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
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                
                // Action buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Copy button
                    IconButton(
                      icon: Icon(
                        Icons.copy_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      onPressed: onCopy,
                      tooltip: 'Copy quote',
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Favorite button
                    IconButton(
                      icon: Icon(
                        quote.isFavorite 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        size: 20,
                        color: quote.isFavorite 
                            ? Colors.red 
                            : Colors.grey[600],
                      ),
                      onPressed: onFavorite,
                      tooltip: quote.isFavorite 
                          ? 'Remove from favorites' 
                          : 'Add to favorites',
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
