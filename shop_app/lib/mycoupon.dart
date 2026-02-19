import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shop_app/customer_registration.dart'; // Ensure path is correct

class ShopInventoryPage extends StatefulWidget {
  const ShopInventoryPage({super.key});

  @override
  State<ShopInventoryPage> createState() => _ShopInventoryPageState();
}

class _ShopInventoryPageState extends State<ShopInventoryPage> {
  final Color _brandColor = const Color(0xFF009ADE);
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final String? shopId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("Stock Inventory", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18)),
      ),
      body: shopId == null
          ? const Center(child: Text("Please Login"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('assigned_coupons')
                  .where('shop_id', isEqualTo: shopId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final displayDocs = allDocs.where((doc) => doc['coupon_code'].toString().toLowerCase().contains(searchQuery.toLowerCase())).toList();

                return Column(
                  children: [
                    // Stats & Search Header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        onChanged: (v) => setState(() => searchQuery = v),
                        decoration: InputDecoration(
                          hintText: "Search coupon code...",
                          prefixIcon: const Icon(LucideIcons.search, size: 18),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: displayDocs.length,
                        itemBuilder: (context, index) {
                          var data = displayDocs[index].data() as Map<String, dynamic>;
                          String code = data['coupon_code'] ?? "";
                          bool isUsed = data['status'] == 'used';

                          return _buildCouponTile(code, isUsed);
                        },
                      ),
                    ),
                  ],
                );
              },
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
      ),
      child: ListTile(
        onTap: isUsed ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CustomerRegistration(preSelectedCoupon: code)),
          );
        },
        leading: Icon(isUsed ? LucideIcons.check : LucideIcons.ticket, color: isUsed ? Colors.grey : _brandColor),
        title: Text(code, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: isUsed ? Colors.grey : Colors.black)),
        subtitle: Text(isUsed ? "Sold Out" : "Available - Tap to register", style: TextStyle(color: isUsed ? Colors.grey : Colors.green, fontSize: 12)),
        trailing: isUsed ? null : const Icon(LucideIcons.chevronRight, size: 16),
      ),
    );
  }
}