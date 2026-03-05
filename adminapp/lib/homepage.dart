import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- PAGE IMPORTS ---
import 'package:adminapp/shoplist.dart';
import 'package:adminapp/type.dart';
import 'package:adminapp/report.dart';
import 'package:adminapp/login.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  static const Color _brandColor = Color(0xFF009ADE);
  static const Color _textPrimary = Color(0xFF1A1A1B);
  static const Color _textSecondary = Color(0xFF64748B);

  // --- SUPPORT NUMBER MANAGEMENT DIALOG ---
  // void _showSupportNumberDialog(BuildContext context) {
  //   final TextEditingController phoneController = TextEditingController();

  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  //       title: Text(
  //         "Support Contact",
  //         style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             "Update the mobile number that shops use for customer support.",
  //             style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
  //           ),
  //           const SizedBox(height: 16),
  //           TextField(
  //             controller: phoneController,
  //             keyboardType: TextInputType.phone,
  //             decoration: InputDecoration(
  //               hintText: "Enter number (e.g. 9188812345)",
  //               prefixIcon: const Icon(LucideIcons.phone, size: 20),
  //               filled: true,
  //               fillColor: const Color(0xFFF5F7F9),
  //               border: OutlineInputBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //                 borderSide: BorderSide.none,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text("Cancel"),
  //         ),
  //         ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: _brandColor,
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  //           ),
  //           onPressed: () async {
  //             if (phoneController.text.isNotEmpty) {
  //               // Stores number in settings/support for the Shop App to read
  //               await FirebaseFirestore.instance
  //                   .collection('settings')
  //                   .doc('support')
  //                   .set({
  //                 'phone': phoneController.text.trim(),
  //                 'updatedAt': FieldValue.serverTimestamp(),
  //               });
                
  //               if (context.mounted) Navigator.pop(context);
                
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text("Support number updated successfully!"),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );
  //             }
  //           },
  //           child: const Text("Save Number", style: TextStyle(color: Colors.white)),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 32,
              width: 32,
              child: Image.asset(
                'assets/msf2026logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  LucideIcons.shieldCheck,
                  color: _brandColor,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'MSF2026 Admin',
              style: GoogleFonts.exo2(
                color: _brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            onPressed: () => _handleLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. SCROLLABLE CONTENT
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Merchants Association',
                          style: GoogleFonts.poppins(
                            color: _brandColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          'Muvattupuzha Unit',
                          style: GoogleFonts.poppins(
                            color: _textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // DYNAMIC LIVE STATS CARD
                        const _OverallStatsCard(),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Management Console',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              LucideIcons.layoutGrid,
                              size: 16,
                              color: _textSecondary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // RESPONSIVE GRID
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.15,
                          children: [
                            _ActionCard(
                              title: 'Shop Types',
                              subtitle: 'Categories',
                              icon: LucideIcons.layoutGrid,
                              color: Colors.orange,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopTypePage())),
                            ),
                            // _ActionCard(
                            //   title: 'Inventory',
                            //   subtitle: ' Coupons',
                            //   icon: LucideIcons.ticket,
                            //   color: Colors.lightGreen,
                            //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CouponPage())),
                            // ),
                            _ActionCard(
                              title: 'View Shops',
                              subtitle: 'Manage list',
                              icon: LucideIcons.shoppingBag,
                              color: _brandColor,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminShopList())),
                            ),
                            // _ActionCard(
                            //   title: 'Admin Staff',
                            //   subtitle: 'Privileges',
                            //   icon: LucideIcons.userPlus,
                            //   color: Colors.indigo,
                            //   onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRegistration())),
                            // ),
                            
                            // --- SUPPORT CONFIG TILE ---
                            // _ActionCard(
                            //   title: 'Support Desk',
                            //   subtitle: 'Update Line',
                            //   icon: LucideIcons.headset,
                            //   color: Colors.pinkAccent,
                            //   onTap: () => _showSupportNumberDialog(context),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 2. FIXED FOOTER (BUILD BY)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    "BUILD BY",
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Image.asset(
                    'assets/psst.png',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Text(
                      "Progressive Software Solutions",
                      style: GoogleFonts.poppins(fontSize: 10, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}

// --- STATS CARD COMPONENT ---
class _OverallStatsCard extends StatelessWidget {
  const _OverallStatsCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('customers').snapshots(),
      builder: (context, snapshot) {
        String total = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF009ADE), Color(0xFF0079B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF009ADE).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Analytics',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(LucideIcons.trendingUp, color: Colors.white54, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                total,
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Coupons Sold Globally',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalReportPage())),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Detailed Sales Reports',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.chevronRight, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- MENU CARD COMPONENT ---
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}