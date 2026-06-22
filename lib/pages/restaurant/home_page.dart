import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_list_page.dart';
import 'restaurant_details_page.dart';
import '../profile/user_profile_page.dart';
import 'favourite_restaurant_page.dart';
import '../../widgets/app_drawer.dart';
import 'notifications_list_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final String? manualUid; // NEW: To handle bypass login for fake emails

  const HomePage({super.key, this.user, this.manualUid});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _showGoal = false;

  void _triggerGoal() {
    setState(() => _showGoal = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showGoal = false);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    // Gunakan manualUid jika ada, jika tidak guna authUser!.uid
    final currentUserId = widget.manualUid ?? authUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.white), 
        title: const Text('HalalEats', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
            builder: (context, snapshot) {
              bool showRedDot = false;
              if (snapshot.hasData && snapshot.data!.exists) {
                var data = snapshot.data!.data() as Map<String, dynamic>;
                
                // Show dot if Welcome is not cleared
                bool isWelcomeCleared = data['isWelcomeCleared'] ?? false;
                if (!isWelcomeCleared) showRedDot = true;

                // Show dot if Profile is incomplete AND alert not cleared
                bool isAlertCleared = data['isAlertCleared'] ?? false;
                bool isProfileIncomplete = data['address'] == null || data['address'].toString().isEmpty;
                if (isProfileIncomplete && !isAlertCleared) showRedDot = true;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsListPage(manualUid: widget.manualUid))), 
                    icon: const Icon(Icons.notifications_none_outlined, size: 28, color: Colors.white)
                  ),
                  if (showRedDot)
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 8, minHeight: 8)),
                    ),
                ],
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AppDrawer(onTabRequested: (index) => setState(() => _selectedIndex = index), manualUid: widget.manualUid),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE8F1ED), Color(0xFFDEEBE6), Color(0xFFD4E5DF)],
                ),
              ),
            ),
          ),
          Positioned(top: 100, right: -40, child: Icon(Icons.eco_rounded, size: 300, color: const Color(0xFF1B4332).withOpacity(0.06))),
          Positioned(bottom: 50, left: -30, child: Icon(Icons.restaurant_rounded, size: 200, color: const Color(0xFF1B4332).withOpacity(0.06))),
          _buildBody(currentUserId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantListPage(manualUid: widget.manualUid))).then((_) => setState(() {}));
          } else { setState(() => _selectedIndex = index); }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B4332),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), label: 'Favourites'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildBody(String? userId) {
    if (_selectedIndex == 2) return FavouriteRestaurantPage(showBackButton: true, onBack: () => setState(() => _selectedIndex = 0), manualUid: userId);
    if (_selectedIndex == 3) return UserProfilePage(onBack: () => setState(() => _selectedIndex = 0), manualUid: userId);
    
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantListPage(manualUid: widget.manualUid))),
              child: AbsorbPointer(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    fillColor: Colors.white,
                    filled: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFF1B4332), borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Discover\nHalal Gems', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Taste the authenticity', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: _triggerGoal,
                        child: const Icon(Icons.sports_soccer, color: Colors.white, size: 50).animate(target: _showGoal ? 1 : 0).rotate(duration: 500.ms).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
                      ),
                      if (_showGoal)
                        Positioned(
                          right: 0, top: -20,
                          child: const Text('GOAL!!!', style: TextStyle(color: Colors.yellow, fontSize: 24, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, shadows: [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))])).animate().fade().scale(duration: 300.ms, curve: Curves.bounceOut).moveY(begin: 0, end: -40, duration: 600.ms).fadeOut(delay: 1.seconds),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Popular Restaurants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('restaurants').where('isHeader', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No restaurants found'));
                final restaurants = snapshot.data!.docs;
                return LayoutBuilder(builder: (context, constraints) {
                    int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : 2);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 16, mainAxisSpacing: 20, childAspectRatio: 0.75),
                      itemCount: restaurants.length,
                      itemBuilder: (context, index) {
                        final doc = restaurants[index]; 
                        final res = doc.data() as Map<String, dynamic>;
                        String imageUrl = res['imageUrl'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&q=80';
                        return _buildPortraitRestaurantCard(doc.id, res['name'] ?? 'No Name', res['rating'] ?? '0.0', res['location'] ?? 'Setapak, KL', imageUrl, res['category'] ?? 'halal');
                      },
                    );
                  });
              }),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitRestaurantCard(String id, String name, String rating, String location, String imageUrl, String category) {
    String label = 'HALAL';
    Color labelColor = const Color(0xFF2D6A4F);
    Color bgColor = const Color(0xFFE8F5E9);
    if (category == 'non-halal') { label = 'NON-HALAL'; labelColor = Colors.red.shade800; bgColor = Colors.red.shade50; }
    else if (category == 'vege') { label = 'VEGE'; labelColor = Colors.orange.shade800; bgColor = Colors.orange.shade50; }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailsPage(
        restaurantId: id, 
        name: name, 
        rating: rating, 
        distance: '', 
        imageUrl: imageUrl,
        manualUid: widget.manualUid, // Hantar ID ke halaman details
      ))).then((_) => setState(() {})),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: const Icon(Icons.restaurant, color: Colors.grey)))),
                    Positioned(top: 8, right: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(color: labelColor, fontSize: 8, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 4),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('reviews').where('restaurantName', isEqualTo: name.trim()).snapshots(),
                        builder: (context, snap) {
                          int count = snap.hasData ? snap.data!.docs.length : 0;
                          return Text('($count)', style: TextStyle(color: Colors.grey.shade600, fontSize: 11));
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 12),
                      const SizedBox(width: 2),
                      Expanded(child: Text(location, style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
