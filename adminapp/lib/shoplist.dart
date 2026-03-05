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

  // --- PAGINATION STATE ---
  final ScrollController _scrollController = ScrollController();
  final List<DocumentSnapshot> _shops = [];
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isInitialLoad = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 25;

  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && _hasMore && !_isLoading) {
        _fetchShops();
      }
    });
  }

  Future<void> _fetchShops() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);

    try {
      // Note: Inequality filter field must be the first orderBy
      Query query = FirebaseFirestore.instance
          .collection('shop')
          .where('status', isNotEqualTo: 'blocked')
          .orderBy('status')
          .orderBy('shop_name')
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      if (snapshot.docs.length < _pageSize) _hasMore = false;

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        _shops.addAll(snapshot.docs);
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredShops = _shops.where((doc) {
      final name = doc['shop_name'].toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase());
    }).toList();

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
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(
                hintText: "Search loaded shops...",
                prefixIcon: Icon(LucideIcons.search, color: _brandColor),
                filled: true,
                fillColor: _inputBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isInitialLoad
                ? Center(child: CircularProgressIndicator(color: _brandColor))
                : filteredShops.isEmpty
                    ? _buildNoDataFound()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredShops.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == filteredShops.length) {
                            return _isLoading ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())) : const SizedBox.shrink();
                          }
                          var data = filteredShops[index].data() as Map<String, dynamic>;
                          return _buildShopCard(filteredShops[index].id, data);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No shops found", style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildShopCard(String shopId, Map<String, dynamic> data) {
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
              trailing: IconButton(
                icon: const Icon(LucideIcons.phone, color: Colors.green, size: 20),
                onPressed: () => _makeCall(data['contact']),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _manageCouponsDialog(context, shopId, data['shop_name'] ?? ""),
                icon: const Icon(LucideIcons.ticket, size: 16),
                label: const Text("MANAGE INVENTORY"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

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
            height: 550,
            child: Column(
              children: [
                TabBar(labelColor: _brandColor, indicatorColor: _brandColor, tabs: const [Tab(text: "Current stock"), Tab(text: "Assign New")]),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PaginatedStockList(shopId: shopId),
                      _buildAssignmentForm(shopId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentForm(String shopId) {
    final sCtrl = TextEditingController();
    final eCtrl = TextEditingController();
    bool isProcessing = false;

    return StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Centered form
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("Assign Range", textAlign: TextAlign.center, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: _brandColor)),
            const SizedBox(height: 8),
            const Text("Enter numeric sequence", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 30),
            TextField(
              controller: sCtrl,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "Start Number",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: _inputBg,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: eCtrl,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: "End Number",
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: _inputBg,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isProcessing
                  ? null
                  : () async {
                      if (sCtrl.text.isEmpty || eCtrl.text.isEmpty) return;
                      setState(() => isProcessing = true);
                      await _assignDirectRange(shopId, int.parse(sCtrl.text), int.parse(eCtrl.text));
                      if (mounted) Navigator.pop(context);
                    },
              child: isProcessing ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("CONFIRM ASSIGNMENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignDirectRange(String shopId, int start, int end) async {
    final firestore = FirebaseFirestore.instance;
    String pad(int n) => n.toString().padLeft(6, '0');
    try {
      final existingDocs = await firestore.collection('assigned_coupons').where(FieldPath.documentId, isGreaterThanOrEqualTo: pad(start)).where(FieldPath.documentId, isLessThanOrEqualTo: pad(end)).get();
      if (existingDocs.docs.isNotEmpty) throw "Range overlap detected.";

      WriteBatch batch = firestore.batch();
      int operationCount = 0;
      for (int i = start; i <= end; i++) {
        String code = pad(i);
        batch.set(firestore.collection('assigned_coupons').doc(code), {'coupon_code': code, 'shop_id': shopId, 'assignedAt': FieldValue.serverTimestamp(), 'status': 'unused'});
        operationCount++;
        if (operationCount == 500) {
          await batch.commit();
          batch = firestore.batch();
          operationCount = 0;
        }
      }
      if (operationCount > 0) await batch.commit();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success: Range Assigned"), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// --- NEW COMPONENT: PAGINATED STOCK LIST WITHIN DIALOG ---
class _PaginatedStockList extends StatefulWidget {
  final String shopId;
  const _PaginatedStockList({required this.shopId});

  @override
  State<_PaginatedStockList> createState() => _PaginatedStockListState();
}

class _PaginatedStockListState extends State<_PaginatedStockList> {
  final List<DocumentSnapshot> _stock = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;
  final ScrollController _listScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMoreStock();
    _listScroll.addListener(() {
      if (_listScroll.position.pixels >= _listScroll.position.maxScrollExtent - 50 && _hasMore && !_isLoading) {
        _fetchMoreStock();
      }
    });
  }

  Future<void> _fetchMoreStock() async {
    setState(() => _isLoading = true);
    Query query = FirebaseFirestore.instance.collection('assigned_coupons').where('shop_id', isEqualTo: widget.shopId).orderBy(FieldPath.documentId).limit(20);
    if (_lastDoc != null) query = query.startAfterDocument(_lastDoc!);

    final snap = await query.get();
    if (snap.docs.length < 20) _hasMore = false;
    if (snap.docs.isNotEmpty) {
      _lastDoc = snap.docs.last;
      _stock.addAll(snap.docs);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_stock.isEmpty && !_isLoading) return const Center(child: Text("No Stock assigned"));
    return ListView.builder(
      controller: _listScroll,
      itemCount: _stock.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _stock.length) return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
        var doc = _stock[index];
        return ListTile(
          title: Text(doc['coupon_code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          // trailing: IconButton(
          //   icon: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 18),
          //   onPressed: () async {
          //     await FirebaseFirestore.instance.collection('assigned_coupons').doc(doc.id).delete();
          //     setState(() => _stock.removeAt(index));
          //   },
          // ),
        );
      },
    );
  }

  @override
  void dispose() {
    _listScroll.dispose();
    super.dispose();
  }
}