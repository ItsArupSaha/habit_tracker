import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quote.dart';

class QuotesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Fetch random quotes from Quotable API
  Future<List<Quote>> getRandomQuotes({int count = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.quotable.io/quotes/random?limit=$count'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final quotes = data.map((json) => Quote.fromApi(json)).toList();
        
        // Check which quotes are already favorited
        await _checkFavorites(quotes);
        
        return quotes;
      } else {
        throw Exception('Failed to load quotes: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local quotes if API fails
      return _getFallbackQuotes(count);
    }
  }
  
  // Add quote to favorites
  Future<void> addToFavorites(Quote quote) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quote.id)
          .set({
        'text': quote.text,
        'author': quote.author,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }
  
  // Remove quote from favorites
  Future<void> removeFavorite(String quoteId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quoteId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }
  
  // Get user's favorite quotes
  Future<List<Quote>> getFavoriteQuotes() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .orderBy('addedAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Quote(
          id: doc.id,
          text: data['text'] ?? '',
          author: data['author'] ?? 'Unknown',
          isFavorite: true,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get favorite quotes: $e');
    }
  }
  
  // Check which quotes are already favorited
  Future<void> _checkFavorites(List<Quote> quotes) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      final favoriteIds = await _getFavoriteQuoteIds(user.uid);
      
      for (int i = 0; i < quotes.length; i++) {
        if (favoriteIds.contains(quotes[i].id)) {
          quotes[i] = quotes[i].copyWith(isFavorite: true);
        }
      }
    } catch (e) {
      // Silently fail - quotes will just show as not favorited
    }
  }
  
  // Get list of favorite quote IDs
  Future<Set<String>> _getFavoriteQuoteIds(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toSet();
    } catch (e) {
      return <String>{};
    }
  }
  
  // Fallback quotes if API fails
  List<Quote> _getFallbackQuotes(int count) {
    final fallbackQuotes = [
      Quote(
        id: 'fallback_1',
        text: 'The only way to do great work is to love what you do.',
        author: 'Steve Jobs',
      ),
      Quote(
        id: 'fallback_2',
        text: 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        author: 'Winston Churchill',
      ),
      Quote(
        id: 'fallback_3',
        text: 'The future belongs to those who believe in the beauty of their dreams.',
        author: 'Eleanor Roosevelt',
      ),
      Quote(
        id: 'fallback_4',
        text: 'It does not matter how slowly you go as long as you do not stop.',
        author: 'Confucius',
      ),
      Quote(
        id: 'fallback_5',
        text: 'The only limit to our realization of tomorrow will be our doubts of today.',
        author: 'Franklin D. Roosevelt',
      ),
      Quote(
        id: 'fallback_6',
        text: 'Believe you can and you\'re halfway there.',
        author: 'Theodore Roosevelt',
      ),
      Quote(
        id: 'fallback_7',
        text: 'Don\'t watch the clock; do what it does. Keep going.',
        author: 'Sam Levenson',
      ),
      Quote(
        id: 'fallback_8',
        text: 'The best way to predict the future is to create it.',
        author: 'Peter Drucker',
      ),
      Quote(
        id: 'fallback_9',
        text: 'What you get by achieving your goals is not as important as what you become by achieving your goals.',
        author: 'Zig Ziglar',
      ),
      Quote(
        id: 'fallback_10',
        text: 'The journey of a thousand miles begins with one step.',
        author: 'Lao Tzu',
      ),
    ];
    
    // Return requested number of quotes (or all if count > available)
    return fallbackQuotes.take(count).toList();
  }
}
