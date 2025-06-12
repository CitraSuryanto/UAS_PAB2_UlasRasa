import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reviewrestopab2/pages/homedetail.dart';
import 'package:reviewrestopab2/pages/homelistitem.dart';

class FavoritesPage extends StatefulWidget {
  final String userId;

  const FavoritesPage({super.key, required this.userId});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  Set<String> favoriteRestoIds = {};

  @override
  void initState() {
    super.initState();
    fetchFavoriteRestoIds();
  }

  Future<void> fetchFavoriteRestoIds() async {
    try {
      // Ambil semua dokumen di koleksi `favorites` dengan userId terkait
      QuerySnapshot favoriteSnapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: widget.userId)
          .get();

      // Simpan hotelId ke dalam set
      setState(() {
        favoriteRestoIds = favoriteSnapshot.docs
            .map((doc) => doc['restoId'] as String)
            .toSet();
      });
    } catch (e) {
      print("Error fetching favorite resto IDs: $e");
    }
  }

  Future<void> toggleFavoriteStatus(DocumentSnapshot resto) async {
    try {
      String restoId = resto.id;

      if (favoriteRestoIds.contains(restoId)) {
        // Hapus dari favorit
        await FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: widget.userId)
            .where('restoId', isEqualTo: restoId)
            .get()
            .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        setState(() {
          favoriteRestoIds.remove(restoId);
        });
      } else {
        // Tambahkan ke favorit
        await FirebaseFirestore.instance.collection('favorites').add({
          'userId': widget.userId,
          'hotelId': restoId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          favoriteRestoIds.add(restoId);
        });
      }
    } catch (e) {
      print("Error toggling favorite status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorite Resto',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: favoriteRestoIds.isEmpty
          ? const Center(child: Text('No favorite resto found.'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('resto').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No resto found.'));
          } else {
            // Filter resto favorit
            var resto = snapshot.data!.docs.where((resto) {
              return favoriteRestoIds.contains(resto.id);
            }).toList();

            return ListView.builder(
              itemCount: resto.length,
              itemBuilder: (context, index) {
                DocumentSnapshot restos = resto[index];
                return RestoListItem(
                  resto: restos,
                  isFavorite: favoriteRestoIds.contains(restos.id),
                  onFavoriteToggle: () => toggleFavoriteStatus(restos),
                  onTap: () async {
                    bool? shouldRefresh = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestoDetailPage(resto: restos),
                      ),
                    );
                    if (shouldRefresh == true) {
                      fetchFavoriteRestoIds();
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
