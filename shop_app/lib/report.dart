import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ShopSalesAnalytics extends StatefulWidget {
  const ShopSalesAnalytics({super.key});

  @override
  State<ShopSalesAnalytics> createState() => _ShopSalesAnalyticsState();
}

class _ShopSalesAnalyticsState extends State<ShopSalesAnalytics> {
  final Color _brandColor = const Color(0xFF009ADE);
  DateTimeRange? _selectedRange;
  bool _isAllTime = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Stream<QuerySnapshot> _getSalesStream() {
    String? shopId = FirebaseAuth.instance.currentUser?.uid;
    Query query = FirebaseFirestore.instance
        .collection('customers')
        .where('shop_id', isEqualTo: shopId);

    if (!_isAllTime && _selectedRange != null) {
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: _selectedRange!.start)
          .where('createdAt', isLessThanOrEqualTo: _selectedRange!.end);
    }
    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Coupon Selling Report",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.calendarRange, color: _brandColor),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getSalesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];
          int totalSold = docs.length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _filterChip(
                      "Today",
                      () {
                        final now = DateTime.now();
                        setState(() {
                          _isAllTime = false;
                          _selectedRange = DateTimeRange(
                            start: DateTime(now.year, now.month, now.day),
                            end: DateTime(
                              now.year,
                              now.month,
                              now.day,
                              23,
                              59,
                              59,
                            ),
                          );
                        });
                      },
                      !_isAllTime &&
                          _selectedRange?.start.day == DateTime.now().day,
                    ),
                    const SizedBox(width: 8),
                    _filterChip(
                      "All Time",
                      () => setState(() => _isAllTime = true),
                      _isAllTime,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _isAllTime
                      ? "Overall Statistics"
                      : "${DateFormat('dd MMM').format(_selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedRange!.end)}",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 10),
                _buildTotalCard(totalSold),
                const SizedBox(height: 40),
                Text(
                  "Selling Trend",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // --- NEW LINE CHART ---
                SizedBox(
                  height: 250,
                  child: totalSold == 0
                      ? Center(
                          child: Text(
                            "No sales data available",
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        )
                      : LineChart(_getLineChartData(docs)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- CHART LOGIC ---
  LineChartData _getLineChartData(List<QueryDocumentSnapshot> docs) {
    bool isSingleDay =
        !_isAllTime && _selectedRange?.start.day == _selectedRange?.end.day;
    Map<int, int> dataMap = {};

    if (isSingleDay) {
      for (int i = 0; i < 24; i++) dataMap[i] = 0;
      for (var doc in docs) {
        int hour = (doc['createdAt'] as Timestamp).toDate().hour;
        dataMap[hour] = (dataMap[hour] ?? 0) + 1;
      }
    } else {
      for (var doc in docs) {
        int day = (doc['createdAt'] as Timestamp).toDate().day;
        dataMap[day] = (dataMap[day] ?? 0) + 1;
      }
    }

    final sortedKeys = dataMap.keys.toList()..sort();
    final spots = sortedKeys
        .map((k) => FlSpot(k.toDouble(), dataMap[k]!.toDouble()))
        .toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (v) =>
            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (val, meta) => Text(
              val.toInt().toString(),
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              if (isSingleDay) {
                if (val % 6 == 0)
                  return Text(
                    "${val.toInt()}:00",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
              } else {
                if (val % 5 == 0)
                  return Text(
                    val.toInt().toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true, // Smooth Curves
          color: _brandColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: spots.length < 31,
          ), // Only show dots if list isn't too crowded
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _brandColor.withOpacity(0.3),
                _brandColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((s) {
              return LineTooltipItem(
                "${s.y.toInt()} Coupons",
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  // --- HELPER WIDGETS ---
  Widget _buildTotalCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "$total",
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "Total Coupons Sold",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onTap, bool isActive) {
    return ActionChip(
      onPressed: onTap,
      label: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
      backgroundColor: isActive ? _brandColor : Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: _brandColor)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _isAllTime = false;
        _selectedRange = DateTimeRange(
          start: DateTime(
            picked.start.year,
            picked.start.month,
            picked.start.day,
          ),
          end: DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          ),
        );
      });
    }
  }
}
