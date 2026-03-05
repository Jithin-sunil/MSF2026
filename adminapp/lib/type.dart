import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ShopTypePage extends StatefulWidget {
  const ShopTypePage({super.key});

  @override
  State<ShopTypePage> createState() => _ShopTypePageState();
}

class _ShopTypePageState extends State<ShopTypePage> {
  final TextEditingController typeController = TextEditingController();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isLoading = false;

  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _inputBg = const Color(0xFFF5F7F9);

  Future<void> insertType() async {
    String typeName = typeController.text.trim();

    if (typeName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a shop type name"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      // Updated collection name to 'shop_types' for consistency
      await firestore.collection('types').add({
        'type_name': typeName,
        'created_at': FieldValue.serverTimestamp(),
      });

      typeController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop Type added successfully!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> deleteType(String docId) async {
    try {
      await firestore.collection('types').doc(docId).delete();
    } catch (e) {
      debugPrint("Delete failed: $e");
    }
  }

  @override
  void dispose() {
    typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Manage Shop Types", style: GoogleFonts.poppins(color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add New Category", style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: typeController,
                    style: GoogleFonts.poppins(color: _textPrimary),
                    decoration: InputDecoration(
                      hintText: "e.g. Bakery, Textiles",
                      prefixIcon: Icon(LucideIcons.store, color: _brandColor, size: 20),
                      filled: true,
                      fillColor: _inputBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 48, width: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : insertType,
                    style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(LucideIcons.plus, size: 24, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text("Existing Types (A-Z)", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: _textPrimary)),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('types')
                    .orderBy('type_name', descending: false) // CHANGED: Order by name A-Z
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Something went wrong"));
                  if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: _brandColor));
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No shop types found"));

                  return ListView.separated(
                    itemCount: snapshot.data!.docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Icon(LucideIcons.tag, color: _brandColor, size: 18),
                          title: Text(data['type_name'] ?? 'Unnamed', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, color: _textPrimary, fontSize: 15)),
                          trailing: IconButton(
                            icon: Icon(LucideIcons.trash2, color: Colors.red[300], size: 20),
                            onPressed: () => _confirmDelete(context, doc.id, data['type_name']),
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId, String? name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Type?"),
        content: Text("Confirm removing '$name'?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              deleteType(docId);
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}