import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminShopList extends StatefulWidget {
  const AdminShopList({super.key});

  @override
  State<AdminShopList> createState() => _AdminShopListState();
}

class _AdminShopListState extends State<AdminShopList> {
  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;
  final Color _inputBg = const Color(0xFFF5F7F9);
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  // --- CORE LOGIC: ASSIGN RANGE (Sequential & Zero-Padded) ---
  Future<void> _assignDirectRange(String shopId, int start, int end) async {
    final firestore = FirebaseFirestore.instance;
    
    // We use 6-digit padding (000001) to ensure strings sort numerically in Firestore
    String pad(int n) => n.toString().padLeft(6, '0');

    try {
      // 1. High-speed duplicate check
      // Checks if any document in the exact range already exists in 'assigned_coupons'
      final existingDocs = await firestore
          .collection('assigned_coupons')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: pad(start))
          .where(FieldPath.documentId, isLessThanOrEqualTo: pad(end))
          .get();

      if (existingDocs.docs.isNotEmpty) {
        throw "Range Overlap: Some coupons in this range are already assigned to other shops.";
      }

      // 2. Optimized Batch Processing for 1000+ items
      WriteBatch batch = firestore.batch();
      int operationCount = 0;
      int totalAdded = 0;

      for (int i = start; i <= end; i++) {
        String code = pad(i); 
        DocumentReference ref = firestore.collection('assigned_coupons').doc(code);

        batch.set(ref, {
          'coupon_code': code,
          'shop_id': shopId,
          'assignedAt': FieldValue.serverTimestamp(),
          'status': 'unused',
        });

        operationCount++;
        totalAdded++;

        // Commit every 500 operations to stay within Firestore limits
        if (operationCount == 500) {
          await batch.commit();
          batch = firestore.batch();
          operationCount = 0;
        }
      }

      // Commit the final set of operations
      if (operationCount > 0) await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Success: Assigned $totalAdded coupons ($start to $end)"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // --- UI: DIALOG COMPONENTS ---
  void _manageCouponsDialog(BuildContext context, String shopId, String shopName) {
    showDialog(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 400,
            height: 500,
            child: Column(
              children: [
                TabBar(
                  labelColor: _brandColor,
                  indicatorColor: _brandColor,
                  tabs: const [Tab(text: "Current stock"), Tab(text: "Assign New")],
                ),
                Expanded(
                  child: TabBarView(
                    children: [_buildHistory(shopId), _buildForm(shopId)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistory(String shopId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('assigned_coupons')
          .where('shop_id', isEqualTo: shopId)
          .orderBy(FieldPath.documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No coupons assigned."));

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            bool isUsed = doc['status'] == 'used';
            return ListTile(
              title: Text(doc['coupon_code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("Status: ${doc['status']}", 
                style: TextStyle(fontSize: 10, color: isUsed ? Colors.red : Colors.green)),
              trailing: IconButton(
                icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
                onPressed: () => FirebaseFirestore.instance.collection('assigned_coupons').doc(doc.id).delete(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildForm(String shopId) {
    final sCtrl = TextEditingController();
    final eCtrl = TextEditingController();
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setLocalState) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assign New Range", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: sCtrl,
              decoration: const InputDecoration(labelText: "Start Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: eCtrl,
              decoration: const InputDecoration(labelText: "End Number", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: isProcessing
                    ? null
                    : () async {
                        if (sCtrl.text.isEmpty || eCtrl.text.isEmpty) return;
                        setLocalState(() => isProcessing = true);
                        await _assignDirectRange(shopId, int.parse(sCtrl.text), int.parse(eCtrl.text));
                        if (mounted) Navigator.pop(context);
                      },
                child: isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("CONFIRM ASSIGNMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        title: Text("Shop Directory", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black)),
        backgroundColor: _bgPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Search shops...",
                prefixIcon: Icon(LucideIcons.search, color: _brandColor),
                filled: true,
                fillColor: _inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('shop').where('status', isNotEqualTo: 'blocked').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((d) => d['shop_name'].toString().toLowerCase().contains(searchQuery)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(backgroundColor: _brandColor.withOpacity(0.1), child: Icon(LucideIcons.store, color: _brandColor)),
                              title: Text(data['shop_name'] ?? "Shop", style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text("Owner: ${data['owner_name'] ?? 'N/A'}"),
                              trailing: Wrap(
                                children: [
                                  IconButton(icon: const Icon(LucideIcons.phone, color: Colors.green, size: 20), onPressed: () => _makeCall(data['contact'])),
                                  IconButton(icon: const Icon(LucideIcons.userX, color: Colors.redAccent, size: 20), onPressed: () => _blockShop(docs[index].id, data['shop_name'])),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _manageCouponsDialog(context, docs[index].id, data['shop_name'] ?? ""),
                                icon: const Icon(LucideIcons.ticket, size: 16),
                                label: const Text("MANAGE INVENTORY"),
                              ),
                            ),
                          ],
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

  void _blockShop(String id, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Block Shop?"),
        content: Text("Confirm blocking '${name ?? 'this shop'}'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('shop').doc(id).update({'status': 'blocked'});
              Navigator.pop(ctx);
            },
            child: const Text("Block", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}