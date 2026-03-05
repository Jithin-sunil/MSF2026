import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shop_app/customer_registration.dart';

class ShopInventoryPage extends StatefulWidget {
  const ShopInventoryPage({super.key});

  @override
  State<ShopInventoryPage> createState() => _ShopInventoryPageState();
}

class _ShopInventoryPageState extends State<ShopInventoryPage> {
  final Color _brandColor = const Color(0xFF009ADE);

  // --- PAGINATION STATE ---
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _coupons = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 25; // Minimum load per batch

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInventory();
    
    // Detect when user scrolls near the bottom to load more
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 200) {
        _fetchInventory();
      }
    });
  }

  // --- CORE LOGIC: PAGINATED FETCH ---
  Future<void> _fetchInventory() async {
    final String? shopId = FirebaseAuth.instance.currentUser?.uid;
    if (shopId == null || _isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('assigned_coupons')
        .where('shop_id', isEqualTo: shopId)
        .orderBy(FieldPath.documentId) // Essential for range and pagination
        .limit(_pageSize);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      final snapshot = await query.get();

      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          _coupons.addAll(snapshot.docs);
        });
      }
    } catch (e) {
      debugPrint("Fetch Inventory Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Local filtering for search (handles zero-padded IDs)
    final filteredCoupons = _coupons.where((doc) {
      String code = doc['coupon_code'].toString();
      // Match raw number or padded number
      return code.contains(searchQuery) || 
             code.replaceFirst(RegExp(r'^0+'), '').contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Stock Inventory", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)
        ),
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search coupon number...",
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          
          Expanded(
            child: filteredCoupons.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredCoupons.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loading indicator at bottom
                      if (index == filteredCoupons.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      var data = filteredCoupons[index].data() as Map<String, dynamic>;
                      String code = data['coupon_code'] ?? "";
                      bool isUsed = data['status'] == 'used';

                      return _buildCouponTile(code, isUsed);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponTile(String code, bool isUsed) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: isUsed ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomerRegistration(preSelectedCoupon: code)),
          );
        },
        leading: CircleAvatar(
          backgroundColor: isUsed ? Colors.grey.shade100 : _brandColor.withOpacity(0.1),
          child: Icon(
            isUsed ? LucideIcons.circle : LucideIcons.ticket, 
            color: isUsed ? Colors.grey : _brandColor, 
            size: 20
          ),
        ),
        title: Text(code, 
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold, 
            color: isUsed ? Colors.grey : Colors.black
          )
        ),
        subtitle: Text(
          isUsed ? "Sold / Registered" : "Available - Tap to register", 
          style: TextStyle(color: isUsed ? Colors.grey : Colors.green, fontSize: 12)
        ),
        trailing: isUsed ? null : const Icon(LucideIcons.chevronRight, size: 16),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.packageOpen, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Text("No inventory items found", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}