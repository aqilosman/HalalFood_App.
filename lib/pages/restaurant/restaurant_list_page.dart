import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halalfoodapp/pages/restaurant/restaurant_details_page.dart';

class RestaurantListPage extends StatefulWidget {
  final String? initialSearch;
  final String? manualUid; // NEW

  const RestaurantListPage({super.key, this.initialSearch, this.manualUid});
  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  double _minRating = 0.0;

  final List<String> _categories = ['All', 'Halal', 'Non Halal', 'Vege'];
  final List<String> _locations = [
    'All', 'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Melaka', 
    'Negeri Sembilan', 'Pahang', 'Penang', 'Perak', 'Perlis', 'Putrajaya', 
    'Sabah', 'Sarawak', 'Selangor', 'Terengganu'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null) _searchController.text = widget.initialSearch!;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B4332);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Text('Explore Restaurants', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [IconButton(icon: Icon(Icons.tune_rounded, color: primaryColor), onPressed: () => _showFilterBottomSheet(context))],
      ),
      body: Column(children: [
          Padding(padding: const EdgeInsets.all(16.0), child: TextField(controller: _searchController, onChanged: (v) => setState(() {}), decoration: InputDecoration(hintText: 'Search by name or cuisine...', prefixIcon: Icon(Icons.search, color: primaryColor), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 16)))),
          _buildActiveFiltersHeader(),
          Expanded(child: _buildList()),
      ]),
    );
  }

  Widget _buildActiveFiltersHeader() {
    return SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Row(children: [
          _buildFilterChip(_selectedCategory, Icons.category_outlined, () => _showFilterBottomSheet(context)),
          const SizedBox(width: 8),
          _buildFilterChip(_selectedLocation, Icons.location_on_outlined, () => _showFilterBottomSheet(context)),
          const SizedBox(width: 8),
          if (_minRating > 0) _buildFilterChip('${_minRating.toInt()}+ Stars', Icons.star_rounded, () => _showFilterBottomSheet(context)),
    ]));
  }

  Widget _buildFilterChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(avatar: Icon(icon, size: 16, color: const Color(0xFF1B4332)), label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)), onPressed: onTap, backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade200)));
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))), builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
            return Container(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Center(child: Container(width: 40, height: 4, decoration: const BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.all(Radius.circular(10))))),
                  const SizedBox(height: 24),
                  const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, children: _categories.map((c) => ChoiceChip(label: Text(c), selected: _selectedCategory == c, onSelected: (v) => setModalState(() => setState(() => _selectedCategory = c)), selectedColor: const Color(0xFF1B4332), labelStyle: TextStyle(color: _selectedCategory == c ? Colors.white : Colors.black))).toList().cast<Widget>()),
                  const SizedBox(height: 24),
                  const Text('State / Location', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _locations.map((l) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(l), selected: _selectedLocation == l, onSelected: (v) => setModalState(() => setState(() => _selectedLocation = l)), selectedColor: const Color(0xFF1B4332), labelStyle: TextStyle(color: _selectedLocation == l ? Colors.white : Colors.black)))).toList().cast<Widget>())),
                  const SizedBox(height: 24),
                  const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(value: _minRating, min: 0, max: 5, divisions: 5, activeColor: const Color(0xFF1B4332), label: '${_minRating.toInt()} Stars', onChanged: (v) => setModalState(() => setState(() => _minRating = v))),
                  const SizedBox(height: 32),
                  SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 12),
                  Center(child: TextButton(onPressed: () => setModalState(() => setState(() { _selectedCategory = 'All'; _selectedLocation = 'All'; _minRating = 0.0; })), child: const Text('Reset All', style: TextStyle(color: Colors.redAccent)))),
            ]));
        });
    });
  }

  Widget _buildList() {
    Query query = FirebaseFirestore.instance.collection('restaurants').where('isHeader', isEqualTo: true);
    if (_selectedCategory != 'All') query = query.where('category', isEqualTo: _selectedCategory.toLowerCase().replaceAll(' ', '-'));
    return StreamBuilder<QuerySnapshot>(stream: query.snapshots(), builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyResults();
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          bool matchesSearch = data['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
          bool matchesLocation = _selectedLocation == 'All' || data['location'].toString().toLowerCase().contains(_selectedLocation.toLowerCase());
          double rating = double.tryParse(data['rating']?.toString() ?? '0') ?? 0;
          return matchesSearch && matchesLocation && rating >= _minRating;
        }).toList();
        if (filteredDocs.isEmpty) return _buildEmptyResults();
        return ListView.builder(padding: const EdgeInsets.all(16), itemCount: filteredDocs.length, itemBuilder: (context, index) {
            final data = filteredDocs[index].data() as Map<String, dynamic>;
            return _buildListItem(filteredDocs[index].id, data);
        });
    });
  }

  Widget _buildEmptyResults() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade300), const SizedBox(height: 16), const Text('No restaurants found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))]));

  Widget _buildListItem(String id, Map<String, dynamic> data) {
    return Container(margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(contentPadding: const EdgeInsets.all(12), leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(data['imageUrl'], width: 70, height: 70, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 70, height: 70, color: Colors.grey.shade100, child: const Icon(Icons.restaurant, color: Colors.grey)))), title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 16), Text(' ${data['rating']} ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)), Text('• ${data['category'].toString().toUpperCase()}', style: TextStyle(color: const Color(0xFF2D6A4F), fontSize: 10, fontWeight: FontWeight.bold))]), const SizedBox(height: 4), Row(children: [const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14), const SizedBox(width: 4), Expanded(child: Text(data['location'], style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))])]), trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailsPage(restaurantId: id, name: data['name'], rating: data['rating'], distance: data['distance'] ?? '', imageUrl: data['imageUrl'], manualUid: widget.manualUid))),
      ),
    );
  }
}
