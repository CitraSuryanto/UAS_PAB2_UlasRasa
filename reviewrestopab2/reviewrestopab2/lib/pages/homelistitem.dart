import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RestoListItem extends StatefulWidget {
  final DocumentSnapshot resto;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const RestoListItem({super.key,
    required this.resto,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  _RestoListItemState createState() => _RestoListItemState();
}

class _RestoListItemState extends State<RestoListItem> {
  double _averageRating = 0.0;
  bool _isLoading = true; // Track loading state
  String _errorMessage = ''; // Track error message

  @override
  void initState() {
    super.initState();
    _fetchAverageRating();
  }

  Future<void> _fetchAverageRating() async {
    try {
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('resto')
          .doc(widget.resto.id)
          .collection('comments')
          .get();

      if (commentsSnapshot.docs.isNotEmpty) {
        double totalRating = 0.0;
        for (var doc in commentsSnapshot.docs) {
          totalRating += (doc['rating'] ?? 0).toDouble(); // Ensure rating is a double
        }
        setState(() {
          _averageRating = totalRating / commentsSnapshot.docs.length;
        });
      } else {
        setState(() {
          _averageRating = 0.0; // No ratings available
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ratings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false; // Loading complete
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.resto.data() as Map<String, dynamic>;
    return Card(
      color: Colors.white, // Fixed color for the card
      child: ListTile(
        leading: data.containsKey('image')
            ? Image.network(
          data['image'],
          fit: BoxFit.cover,
        )
            : null,
        title: Text(
          data['name'] ?? 'Unknown Resto',
          style: const TextStyle(
            color: Colors.black, // Fixed color for the title
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data['address'] ?? 'No Address',
              style: const TextStyle(
                color: Colors.black87, // Fixed color for the address
              ),
            ),
            Row(
              children: [
                const Text(
                  'Rating: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87, // Fixed color for the rating label
                  ),
                ),
                _isLoading
                    ? const CircularProgressIndicator() // Show loading indicator
                    : RatingBarIndicator(
                  rating: _averageRating,
                  itemBuilder: (context, index) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  itemCount: 5,
                  itemSize: 12.0,
                  direction: Axis.horizontal,
                ),
                Text(
                  _isLoading ? '' : _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87, // Fixed color for the rating value
                  ),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty) // Display error message if any
              Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: widget.isFavorite ? Colors.red : null,
          ),
          onPressed: widget.onFavoriteToggle,
        ),
        onTap: widget.onTap,
      ),
    );
  }
}