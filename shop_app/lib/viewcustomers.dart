import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ViewCustomers extends StatefulWidget {
  const ViewCustomers({super.key});

  @override
  State<ViewCustomers> createState() => _ViewCustomersState();
}

class _ViewCustomersState extends State<ViewCustomers> {
  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;

  // --- PAGINATION STATE ---
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _customerDocs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 25; // Minimum 25 data points per load

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    
    // Listener for infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _fetchMembers();
      }
    });
  }

  // --- CORE LOGIC: FETCH PAGINATED DATA ---
  Future<void> _fetchMembers() async {
    final String? shopId = FirebaseAuth.instance.currentUser?.uid;
    if (shopId == null || _isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('customers')
        .where('shop_id', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .limit(_pageSize);

    // If it's not the first load, start after the last fetched document
    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      final snapshot = await query.get();
      
      // If we received fewer items than requested, we've reached the end
      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          _customerDocs.addAll(snapshot.docs);
        });
      }
    } catch (e) {
      debugPrint("Pagination Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic: Only allow editing/deleting if registered on the current calendar day
  bool _canModify(Timestamp? timestamp) {
    if (timestamp == null) return false;
    DateTime createdDate = timestamp.toDate();
    DateTime now = DateTime.now();
    return createdDate.year == now.year &&
        createdDate.month == now.month &&
        createdDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // Local filter logic (Handles zero-padded searching)
    final filteredDocs = _customerDocs.where((doc) {
      String code = doc['coupon_code'].toString();
      // Allows searching by raw number (e.g., "5" matches "000005")
      return code.contains(searchQuery) || 
             code.replaceFirst(RegExp(r'^0+'), '').contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Registered Members",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search Coupon Number...",
                prefixIcon: Icon(LucideIcons.search, color: _brandColor, size: 20),
                filled: true,
                fillColor: const Color(0xFFF5F7F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: filteredDocs.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredDocs.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show loading spinner at the bottom while fetching more
                      if (index == filteredDocs.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      var doc = filteredDocs[index];
                      var data = doc.data() as Map<String, dynamic>;
                      Timestamp? createdAt = data['createdAt'] as Timestamp?;
                      String couponCode = data['coupon_code'] ?? 'N/A';
                      bool editable = _canModify(createdAt);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: _brandColor.withOpacity(0.1),
                            child: Icon(LucideIcons.user, color: _brandColor, size: 20),
                          ),
                          title: Text(
                            data['name'] ?? 'Guest',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Coupon: $couponCode",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
                                ),
                                Text("Contact: ${data['contact']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          trailing: editable
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                      onPressed: () => _showEditDialog(doc.id, data),
                                    ),
                                    IconButton(
                                      icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20),
                                      onPressed: () => _confirmDelete(doc.id, couponCode),
                                    ),
                                  ],
                                )
                              : Icon(LucideIcons.lock, color: Colors.grey.shade300, size: 16),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.users, size: 60, color: Colors.grey[200]),
          const SizedBox(height: 10),
          Text("No records found", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- ACTIONS: EDIT DIALOG ---
  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final nameEdit = TextEditingController(text: currentData['name']);
    final contactEdit = TextEditingController(text: currentData['contact']);
    final couponEdit = TextEditingController(text: currentData['coupon_code']);
    final String oldCoupon = currentData['coupon_code'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Details", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameEdit, decoration: const InputDecoration(labelText: "Customer Name")),
              const SizedBox(height: 12),
              TextField(controller: contactEdit, decoration: const InputDecoration(labelText: "Contact No"), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(
                controller: couponEdit,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Coupon Number"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              String rawInput = couponEdit.text.trim();
              String newCoupon = rawInput.isEmpty ? oldCoupon : rawInput.padLeft(6, '0');
              
              final firestore = FirebaseFirestore.instance;
              WriteBatch batch = firestore.batch();

              // Update record
              batch.update(firestore.collection('customers').doc(docId), {
                'name': nameEdit.text.trim(),
                'contact': contactEdit.text.trim(),
                'coupon_code': newCoupon,
              });

              // Swap statuses if coupon changed
              if (newCoupon != oldCoupon) {
                batch.update(firestore.collection('assigned_coupons').doc(oldCoupon), {'status': 'unused'});
                batch.update(firestore.collection('assigned_coupons').doc(newCoupon), {'status': 'used'});
              }

              await batch.commit();
              
              // Locally update the list to show changes immediately
              setState(() {
                int index = _customerDocs.indexWhere((d) => d.id == docId);
                if (index != -1) {
                  // This is a simplified local update; in a complex app, refetching or 
                  // using a state manager is preferred.
                  _fetchMembers(); 
                }
              });

              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS: DELETE DIALOG ---
  void _confirmDelete(String docId, String couponCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        content: const Text("This will release the coupon for reuse."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              WriteBatch batch = FirebaseFirestore.instance.batch();
              batch.delete(FirebaseFirestore.instance.collection('customers').doc(docId));
              batch.update(FirebaseFirestore.instance.collection('assigned_coupons').doc(couponCode), {'status': 'unused'});
              await batch.commit();
              
              setState(() {
                _customerDocs.removeWhere((d) => d.id == docId);
              });
              
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
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