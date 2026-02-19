import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CouponPage extends StatefulWidget {
  const CouponPage({super.key});

  @override
  State<CouponPage> createState() => _CouponPageState();
}

class _CouponPageState extends State<CouponPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;

  // --- 1. DETAILS BOTTOM SHEET ---
  void _showCouponDetails(String couponCode, String status) async {
    if (status != 'assigned') return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getAssignmentData(couponCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
            }

            final shop = snapshot.data?['shop'];
            final customer = snapshot.data?['customer'];

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Coupon: $couponCode", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Icon(LucideIcons.ticket, color: Color(0xFF009ADE)),
                    ],
                  ),
                  const Divider(height: 30),
                  Text("ASSIGNED SHOP", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: _brandColor.withOpacity(0.1), child: Icon(LucideIcons.store, color: _brandColor)),
                    title: Text(shop?['shop_name'] ?? "Unknown Shop", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Owner: ${shop?['owner_name'] ?? 'N/A'}"),
                  ),
                  const SizedBox(height: 20),
                  Text("SALES STATUS", style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  customer != null
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.green.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              Row(children: [const Icon(LucideIcons.user, size: 16, color: Colors.green), const SizedBox(width: 10), Text(customer['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold))]),
                              const SizedBox(height: 8),
                              Row(children: [const Icon(LucideIcons.phone, size: 16, color: Colors.green), const SizedBox(width: 10), Text(customer['contact'] ?? "N/A")]),
                            ],
                          ),
                        )
                      : const Text("Available at shop", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getAssignmentData(String code) async {
    var assignSnap = await firestore.collection('assigned_coupons').doc(code).get();
    Map<String, dynamic>? shopData;
    Map<String, dynamic>? customerData;

    if (assignSnap.exists) {
      var shopSnap = await firestore.collection('shop').doc(assignSnap['shop_id']).get();
      shopData = shopSnap.data();
      var custSnap = await firestore.collection('customers').where('coupon_code', isEqualTo: code).limit(1).get();
      if (custSnap.docs.isNotEmpty) customerData = custSnap.docs.first.data();
    }
    return {'shop': shopData, 'customer': customerData};
  }

  // --- 2. UPDATED GENERATION LOGIC WITH DUPLICATE CHECK ---
  Future<void> _generateCoupons(int start, int end) async {
    setState(() => isLoading = true);
    try {
      WriteBatch batch = firestore.batch();
      int operationCount = 0;
      int totalAdded = 0;
      int skippedCount = 0;

      for (int i = start; i <= end; i++) {
        String fullCode = i.toString();
        DocumentReference ref = firestore.collection('coupons').doc(fullCode);

        // Verify if it exists before adding
        DocumentSnapshot check = await ref.get();
        if (!check.exists) {
          batch.set(ref, {
            'code': fullCode,
            'status': 'active',
            'created_at': FieldValue.serverTimestamp(),
          });
          operationCount++;
          totalAdded++;

          if (operationCount >= 500) {
            await batch.commit();
            batch = firestore.batch();
            operationCount = 0;
          }
        } else {
          skippedCount++;
        }
      }

      if (operationCount > 0) await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Added: $totalAdded. Skipped: $skippedCount (Duplicates)."),
            backgroundColor: totalAdded > 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showBulkGenerateDialog() {
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Generate Coupons"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: startCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Start Number")),
            const SizedBox(height: 10),
            TextField(controller: endCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "End Number")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              int? s = int.tryParse(startCtrl.text);
              int? e = int.tryParse(endCtrl.text);
              if (s != null && e != null && s <= e) {
                Navigator.pop(ctx);
                _generateCoupons(s, e);
              }
            },
            child: const Text("Generate"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(backgroundColor: _bgPrimary, elevation: 0, centerTitle: true, title: Text("Inventory Manager", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black))),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: InputDecoration(hintText: "Search Coupon...", prefixIcon: const Icon(LucideIcons.search), filled: true, fillColor: const Color(0xFFF5F7F9), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(width: double.infinity, height: 55, child: ElevatedButton.icon(onPressed: isLoading ? null : _showBulkGenerateDialog, icon: const Icon(LucideIcons.plus), label: const Text("BULK GENERATE NEW RANGE"), style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore.collection('coupons').orderBy('created_at', descending: true).limit(150).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final docs = snapshot.data!.docs.where((doc) => doc['code'].toString().contains(searchQuery)).toList();
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var data = docs[index].data() as Map<String, dynamic>;
                        String code = data['code'] ?? "";
                        String status = data['status'] ?? "";
                        bool isAssigned = status == 'assigned';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _showCouponDetails(code, status),
                            leading: Icon(LucideIcons.ticket, color: isAssigned ? Colors.orange : Colors.green),
                            title: Text(code, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                            trailing: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, color: isAssigned ? Colors.orange : Colors.green, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading) Container(color: Colors.black45, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
        ],
      ),
    );
  }
}