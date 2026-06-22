import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_overview.dart';
import 'my_restaurant.dart';
import 'owner_bookings_page.dart'; // NEW
import '../../widgets/app_drawer.dart';
import '../restaurant/notifications_list_page.dart';

class OwnerScreen extends StatefulWidget {
  final String? manualUid; 
  const OwnerScreen({super.key, this.manualUid});

  @override
  State<OwnerScreen> createState() => _OwnerScreenState();
}

class _OwnerScreenState extends State<OwnerScreen> {
  int _selectedIndex = 0; // Changed to int index for consistency

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUserId = widget.manualUid ?? authUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('restaurants').where('ownerId', isEqualTo: currentUserId).snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> allData = [];
        if (snapshot.hasData) {
          allData = snapshot.data!.docs.map((d) {
            var m = d.data() as Map<String, dynamic>;
            m['id'] = d.id;
            return m;
          }).toList();

          // Sort by updatedAt or createdAt to ensure chronological order
          allData.sort((a, b) {
            Timestamp? tA = a['updatedAt'] ?? a['createdAt'];
            Timestamp? tB = b['updatedAt'] ?? b['createdAt'];
            
            // If both are null, they are equal
            if (tA == null && tB == null) return 0;
            // If only A is null, treat it as the newest (highest)
            if (tA == null) return 1;
            // If only B is null, treat it as the newest (highest)
            if (tB == null) return -1;

            return tA.compareTo(tB);
          });
        }

        final headerData = allData.where((r) => r['isHeader'] == true).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFE8F1ED),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B4332),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              _getPageTitle(), 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)
            ),
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
          drawer: AppDrawer(manualUid: widget.manualUid),
          body: Stack(
            children: [
              Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F1ED), Color(0xFFDEEBE6), Color(0xFFD4E5DF)])))),
              _buildPage(allData, headerData),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF1B4332),
              unselectedItemColor: Colors.grey.shade400,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.event_available_outlined), activeIcon: Icon(Icons.event_available), label: 'Bookings'),
                BottomNavigationBarItem(icon: Icon(Icons.restaurant_outlined), activeIcon: Icon(Icons.restaurant), label: 'Restaurants'),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getPageTitle() {
    if (_selectedIndex == 0) return 'Owner Portal';
    if (_selectedIndex == 1) return 'Manage Bookings';
    return 'My Restaurants';
  }

  Widget _buildPage(List<Map<String, dynamic>> allData, List<Map<String, dynamic>> headerData) {
    if (_selectedIndex == 0) return DashboardOverview(restaurants: allData, manualUid: widget.manualUid);
    if (_selectedIndex == 1) return OwnerBookingsPage(manualUid: widget.manualUid);
    return MyRestaurantsPage(restaurants: headerData, manualUid: widget.manualUid);
  }
}
