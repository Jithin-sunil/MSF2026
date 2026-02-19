import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

// --- PAGE IMPORTS ---
import 'package:shop_app/account.dart';
import 'package:shop_app/login.dart';
import 'package:shop_app/mycoupon.dart';
import 'package:shop_app/report.dart';
import 'package:shop_app/viewcustomers.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _brandColor = Color(0xFF009ADE);
  static const Color _textPrimary = Colors.black;
  static const Color _textSecondary = Color(0xFF757575);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String shopName = user?.displayName ?? "Shop Owner";
    final String shopId = user?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/msf2026logo.png',
              height: 50,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.store, size: 24, color: _brandColor),
            ),
            const SizedBox(width: 10),
            Text(
              'MSF2026',
              style: GoogleFonts.exo2(
                color: _brandColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "My Account",
            icon: const Icon(Icons.account_circle_outlined, color: _textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopAccountPage()),
            ),
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(LucideIcons.logOut, color: Colors.redAccent, size: 20),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (r) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
                    ),
                    Text(
                      shopName.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildDailyStatusCard(shopId),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Store Management',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(LucideIcons.layoutGrid, size: 16, color: _textSecondary),
                      ],
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.15,
                      children: [
                        _buildMenuCard(
                          context,
                          title: 'Inventory',
                          subtitle: 'Manage stock',
                          icon: LucideIcons.package,
                          color: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopInventoryPage()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'My Customers',
                          subtitle: 'View members',
                          icon: LucideIcons.database,
                          color: Colors.indigo,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ViewCustomers()),
                          ),
                        ),
                        _buildMenuCard(
                          context,
                          title: 'Analytics',
                          subtitle: 'Performance',
                          icon: LucideIcons.chartBar,
                          color: Colors.teal,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ShopSalesAnalytics()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // --- FIXED FOOTER SECTION ---
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
                  const SizedBox(height: 2),
                   // --- DEVELOPER COMPANY LOGO ---
                  Image.asset(
                    'assets/psst.png', // Ensure this matches your file name in assets
                    height: 45, // Size adjusted for a footer look
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

  // --- REUSABLE WIDGETS (Keep these the same) ---

  Widget _buildDailyStatusCard(String shopId) {
    DateTime now = DateTime.now();
    DateTime startOfToday = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('customers')
          .where('shop_id', isEqualTo: shopId)
          .where('createdAt', isGreaterThanOrEqualTo: startOfToday)
          .snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "0";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_brandColor, Color(0xFF0079B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _brandColor.withOpacity(0.3),
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
                    'Registrations Today',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(LucideIcons.calendarCheck, color: Colors.white.withOpacity(0.5), size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                count,
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.zap, color: Colors.amber, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "LIVE UPDATES",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _textPrimary),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 9, color: _textSecondary),
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