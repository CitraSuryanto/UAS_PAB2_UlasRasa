import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:reviewrestopab2/pages/addResto.dart';
import 'package:reviewrestopab2/pages/favorite.dart';
import 'package:reviewrestopab2/pages/profile.dart';
import 'package:reviewrestopab2/pages/homedetail.dart';

class HomePage extends StatefulWidget {
  final String userId;

  const HomePage({super.key, required this.userId, required String userRole, required String userName});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<DocumentSnapshot> resto = [];
  List<DocumentSnapshot> filteredResto = [];
  String? bannerUrl;
  String? userName;
  String? userRole;
  String searchQuery = "";
  final double cardHeight = 200;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchResto();
    fetchBanner();
    fetchUserData();
  }

  Future<void> fetchResto() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('resto').get();
    setState(() {
      resto = snapshot.docs;
      filteredResto = resto;
    });
  }

  Future<void> fetchBanner() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('banners').get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        bannerUrl = snapshot.docs.first['url'];
      });
    }
  }

  Future<void> fetchUserData() async {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('profile')
        .doc(widget.userId)
        .get();
    if (snapshot.exists) {
      setState(() {
        userName = snapshot['name'];
        userRole = snapshot['role'];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _filterResto(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredResto = resto.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['name'] ?? '').toString().toLowerCase();
        final address = (data['address'] ?? '').toString().toLowerCase();
        return name.contains(lowerQuery) || address.contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      buildHomeContent(),
      FavoritesPage(userId: widget.userId),
      ProfilePage(userId: widget.userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UlasRasa - Aplikasi Review Restaurant',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueAccent,
        actions: [
          if (userRole == 'admin')
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRestoPage(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Selamat datang, ${userName ?? 'Pengguna'}!',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            onChanged: _filterResto,
            decoration: InputDecoration(
              hintText: 'Cari restoran berdasarkan nama atau alamat...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (bannerUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                bannerUrl!,
                fit: BoxFit.cover,
                height: 150,
                width: double.infinity,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: filteredResto.isEmpty
              ? const Center(child: Text('Tidak ada restoran yang ditemukan.'))
              : ListView.builder(
            itemCount: filteredResto.length,
            itemBuilder: (context, index) {
              var restos = filteredResto[index].data() as Map<String, dynamic>;
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RestoDetailPage(resto: filteredResto[index]),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12.0),
                          bottomLeft: Radius.circular(12.0),
                        ),
                        child: Image.network(
                          restos['image'] ?? 'https://via.placeholder.com/150',
                          height: cardHeight,
                          width: cardHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restos['name'] ?? 'Nama Restaurant',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                restos['description'] ?? 'Deskripsi tidak tersedia',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 18),
                                  const SizedBox(width: 4),
                                  FutureBuilder<double>(
                                    future: calculateAverageRating(filteredResto[index].id),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Text('Loading...');
                                      } else if (snapshot.hasError) {
                                        return const Text('Error');
                                      } else {
                                        return Text(
                                          '${snapshot.data?.toStringAsFixed(1) ?? 'N/A'}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<double> calculateAverageRating(String restoId) async {
    QuerySnapshot commentsSnapshot = await FirebaseFirestore.instance
        .collection('resto')
        .doc(restoId)
        .collection('comments')
        .get();

    if (commentsSnapshot.docs.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var doc in commentsSnapshot.docs) {
      totalRating += doc['rating'] ?? 0.0;
    }

    return totalRating / commentsSnapshot.docs.length;
  }
}
