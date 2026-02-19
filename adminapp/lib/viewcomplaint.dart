import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

class AdminViewComplaints extends StatefulWidget {
  const AdminViewComplaints({super.key});

  @override
  State<AdminViewComplaints> createState() => _AdminViewComplaintsState();
}

class _AdminViewComplaintsState extends State<AdminViewComplaints> {
  // --- BRAND COLORS ---
  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;
  final Color _textPrimary = Colors.black;

  // --- HELPER: Fetch Shop Name from 'shop' collection ---
  Future<String> _getShopName(String shopId) async {
    try {
      var doc = await FirebaseFirestore.instance
          .collection('shop')
          .doc(shopId)
          .get();
      if (doc.exists) {
        return doc.data()?['shop_name'] ?? "Unnamed Shop";
      }
    } catch (e) {
      return "Error loading name";
    }
    return "Shop Not Found";
  }

  // --- REPLY DIALOG LOGIC ---
  void _showReplyDialog(BuildContext context, String docId) {
    final TextEditingController replyController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              "Send Reply",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Providing a reply will set the status to 'Replied'.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: replyController,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Enter your response...",
                    filled: true,
                    fillColor: const Color(0xFFF5F7F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandColor),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (replyController.text.trim().isEmpty) return;

                        setDialogState(() => isSubmitting = true);

                        try {
                          await FirebaseFirestore.instance
                              .collection('complaints')
                              .doc(docId)
                              .update({
                                'status': 'Replied',
                                'admin_reply': replyController.text.trim(),
                                'repliedAt': FieldValue.serverTimestamp(),
                              });
                          if (!mounted) return;
                          Navigator.pop(ctx);
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Send Reply",
                        style: TextStyle(color: Colors.white),
                      ),
              ),
            ],
          );
        },
      ),
    );
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
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Complaints",
          style: GoogleFonts.poppins(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('complaints')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _brandColor));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No complaints found",
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String shopId = data['shop_id'] ?? "";
              Timestamp? time = data['createdAt'] as Timestamp?;
              String formattedDate = time != null
                  ? DateFormat('dd MMM, hh:mm a').format(time.toDate())
                  : '';
              bool hasReplied = data['admin_reply'] != null;

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FutureBuilder<String>(
                          future: _getShopName(shopId),
                          builder: (context, nameSnapshot) {
                            return Text(
                              nameSnapshot.data ?? "Loading...",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _brandColor,
                              ),
                            );
                          },
                        ),
                        _buildStatusBadge(data['status'] ?? 'Pending'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      data['content'] ?? 'No content',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _textPrimary,
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        // Only show Reply button if not already replied
                        if (!hasReplied)
                          TextButton.icon(
                            onPressed: () => _showReplyDialog(context, doc.id),
                            icon: const Icon(LucideIcons.reply, size: 16),
                            label: const Text("Reply"),
                            style: TextButton.styleFrom(
                              foregroundColor: _brandColor,
                            ),
                          )
                        else
                          const Icon(
                            LucideIcons.checkCheck,
                            color: Colors.green,
                            size: 18,
                          ),
                      ],
                    ),
                    if (hasReplied) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Response:",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['admin_reply'],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Replied':
        color = Colors.blue;
        break;
      case 'Resolved':
        color = Colors.green;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      default:
        color = Colors.redAccent;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
