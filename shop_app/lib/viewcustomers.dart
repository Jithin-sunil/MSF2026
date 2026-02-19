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
  final Color _textPrimary = Colors.black;

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
    final String? shopId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Registered Members",
          style: GoogleFonts.poppins(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: shopId == null
          ? const Center(child: Text("Access Denied"))
          : Column(
              children: [
                // --- SEARCH BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => searchQuery = v.toUpperCase()),
                    decoration: InputDecoration(
                      hintText: "Search Coupon Code...",
                      prefixIcon: Icon(
                        LucideIcons.search,
                        color: _brandColor,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF5F7F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('customers')
                        .where('shop_id', isEqualTo: shopId)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: _brandColor),
                        );
                      }

                      // Local filter for Search
                      final docs = snapshot.data!.docs.where((doc) {
                        return doc['coupon_code'].toString().contains(
                          searchQuery,
                        );
                      }).toList();

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          var doc = docs[index];
                          var data = doc.data() as Map<String, dynamic>;
                          Timestamp? createdAt =
                              data['createdAt'] as Timestamp?;
                          String couponCode = data['coupon_code'] ?? 'N/A';
                          bool editable = _canModify(createdAt);

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _brandColor.withOpacity(0.1),
                                child: Icon(
                                  LucideIcons.user,
                                  color: _brandColor,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                data['name'] ?? 'Guest',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Coupon: $couponCode",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text("Contact: ${data['contact']}"),
                                ],
                              ),
                              trailing: editable
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue,
                                            size: 20,
                                          ),
                                          onPressed: () => _showEditDialog(
                                            context,
                                            doc.id,
                                            data,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            LucideIcons.trash2,
                                            color: Colors.redAccent,
                                            size: 20,
                                          ),
                                          onPressed: () => _confirmDelete(
                                            context,
                                            doc.id,
                                            couponCode,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Icon(
                                      LucideIcons.lock,
                                      color: Colors.grey,
                                      size: 16,
                                    ),
                            ),
                          );
                        },
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
          const Text("No matching records found"),
        ],
      ),
    );
  }

  // --- ACTIONS: EDIT DIALOG (WITH COUPON EDIT) ---
  void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> currentData,
  ) {
    final nameEdit = TextEditingController(text: currentData['name']);
    final contactEdit = TextEditingController(text: currentData['contact']);
    final couponEdit = TextEditingController(text: currentData['coupon_code']);
    final String oldCoupon = currentData['coupon_code'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Member",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameEdit,
                decoration: const InputDecoration(labelText: "Customer Name"),
              ),
              TextField(
                controller: contactEdit,
                decoration: const InputDecoration(labelText: "Contact No"),
                keyboardType: TextInputType.phone,
              ),
              TextField(
                controller: couponEdit,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "Coupon Code",
                  hintText: "Update if assigned wrongly",
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
            onPressed: () async {
              String newCoupon = couponEdit.text.trim().toUpperCase();
              final firestore = FirebaseFirestore.instance;
              WriteBatch batch = firestore.batch();

              // 1. Update Customer Record
              batch.update(firestore.collection('customers').doc(docId), {
                'name': nameEdit.text.trim(),
                'contact': contactEdit.text.trim(),
                'coupon_code': newCoupon,
              });

              // 2. If coupon changed, swap statuses in assigned_coupons table
              if (newCoupon != oldCoupon) {
                batch.update(
                  firestore.collection('assigned_coupons').doc(oldCoupon),
                  {'status': 'unused'},
                );
                batch.update(
                  firestore.collection('assigned_coupons').doc(newCoupon),
                  {'status': 'used'},
                );
              }

              await batch.commit();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text(
              "Update All",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- ACTIONS: DELETE LOGIC ---
  void _confirmDelete(BuildContext context, String docId, String couponCode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              WriteBatch batch = FirebaseFirestore.instance.batch();
              batch.delete(
                FirebaseFirestore.instance.collection('customers').doc(docId),
              );
              batch.update(
                FirebaseFirestore.instance
                    .collection('assigned_coupons')
                    .doc(couponCode),
                {'status': 'unused'},
              );
              await batch.commit();
              Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
