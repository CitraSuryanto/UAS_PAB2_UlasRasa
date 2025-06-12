import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reviewrestopab2/pages/comment.dart';
import 'package:reviewrestopab2/pages/editResto.dart';
import 'package:url_launcher/url_launcher.dart';

class RestoDetailPage extends StatefulWidget {
  final DocumentSnapshot resto;

  const RestoDetailPage({super.key, required this.resto});

  @override
  _RestoDetailPageState createState() => _RestoDetailPageState();
}

class _RestoDetailPageState extends State<RestoDetailPage> {
  double _averageRating = 0.0;
  bool _isFavorite = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchAverageRating();
    _checkFavoriteStatus();
    _checkAdminRole();
  }

  Future<void> _fetchAverageRating() async {
    final commentsSnapshot = await FirebaseFirestore.instance
        .collection('resto')
        .doc(widget.resto.id)
        .collection('comments')
        .get();

    if (commentsSnapshot.docs.isNotEmpty) {
      double totalRating = 0.0;
      for (var doc in commentsSnapshot.docs) {
        totalRating += doc['rating'];
      }
      setState(() {
        _averageRating = totalRating / commentsSnapshot.docs.length;
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .doc('${user.uid}_${widget.resto.id}')
          .get();
      setState(() {
        _isFavorite = favoriteSnapshot.exists;
      });
    }
  }

  Future<void> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userSnapshot =
      await FirebaseFirestore.instance.collection('profile').doc(user.uid).get();
      if (userSnapshot.exists) {
        setState(() {
          _isAdmin = userSnapshot.data()?['role'] == 'admin';
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoriteRef = FirebaseFirestore.instance
          .collection('favorites')
          .doc('${user.uid}_${widget.resto.id}');

      if (_isFavorite) {
        // Remove from favorites
        await favoriteRef.delete();
      } else {
        // Add to favorites
        await favoriteRef.set({
          'restoId': widget.resto.id,
          'userId': user.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _isFavorite = !_isFavorite;
      });
    }
  }

  Future<void> _deleteResto() async {
    await FirebaseFirestore.instance.collection('resto').doc(widget.resto.id).delete();
    Navigator.pop(context, true); // Navigate back to the previous screen
  }

  @override
  Widget build(BuildContext context) {
    var data = widget.resto.data() as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['name'],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        actions: _isAdmin
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit resto page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditRestoPage(resto: widget.resto),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Show confirmation dialog before deleting
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Delete Resto'),
                    content: const Text(
                        'Are you sure you want to delete this resto?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
                      ),
                      TextButton(
                        onPressed: () {
                          _deleteResto(); // Call delete function
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text('Delete',  style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ]
            : null,
      ),
      body: ListView(
        children: [
          Image.network(data['image']),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'resto ${data['name']}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['description'],
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['address'],
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                IconButton(
                  icon: const Icon(Icons.map),
                  color: Colors.black,
                  onPressed: () async {
                    String url = data['maps'];
                    if (await canLaunch(url)) {
                      await launch(url);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                CommentsSection(restoId: widget.resto.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
