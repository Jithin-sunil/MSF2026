import 'package:adminapp/singlereport.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart'; // Ensure fl_chart is in pubspec.yaml

class GlobalReportPage extends StatefulWidget {
  const GlobalReportPage({super.key});

  @override
  State<GlobalReportPage> createState() => _GlobalReportPageState();
}

class _GlobalReportPageState extends State<GlobalReportPage> {
  DateTimeRange? _range;
  final Color _brandColor = const Color(0xFF009ADE);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
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
    if (picked != null) setState(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Overall Sales Report",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.calendar, color: _brandColor),
            onPressed: _pickDateRange,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('customers')
            .where('createdAt', isGreaterThanOrEqualTo: _range!.start)
            .where(
              'createdAt',
              isLessThanOrEqualTo: _range!.end.add(const Duration(days: 1)),
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          Map<String, int> shopSalesMap = {};
          Map<String, int> dailyTrend = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String shopId = data['shop_id'] ?? 'Unknown';
            shopSalesMap[shopId] = (shopSalesMap[shopId] ?? 0) + 1;

            // Grouping for Chart
            DateTime date = (data['createdAt'] as Timestamp).toDate();
            String dayKey = DateFormat('dd MMM').format(date);
            dailyTrend[dayKey] = (dailyTrend[dayKey] ?? 0) + 1;
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Stats Header
                _buildStatsHeader(docs.length),

                // 2. Global Graph Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sales Trend",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGlobalChart(dailyTrend),
                      ],
                    ),
                  ),
                ),

                // 3. Shop Performance List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Performance by Shop",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                if (shopSalesMap.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("No sales found in this period"),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: shopSalesMap.length,
                    itemBuilder: (context, index) {
                      var entry = shopSalesMap.entries.toList()[index];
                      return _ShopSalesTile(
                        shopId: entry.key,
                        salesCount: entry.value,
                        brandColor: _brandColor,
                      );
                    },
                  ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(int total) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
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
            "${DateFormat('dd MMM').format(_range!.start)} - ${DateFormat('dd MMM yyyy').format(_range!.end)}",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total.toString(),
            style: GoogleFonts.poppins(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            "TOTAL COUPONS SOLD",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalChart(Map<String, int> dailyTrend) {
    if (dailyTrend.isEmpty)
      return const SizedBox(
        height: 150,
        child: Center(child: Text("Not enough data")),
      );

    List<String> sortedLabels = dailyTrend.keys.toList();
    List<FlSpot> spots = [];
    for (int i = 0; i < sortedLabels.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTrend[sortedLabels[i]]!.toDouble()));
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, m) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  int idx = v.toInt();
                  if (idx >= 0 && idx < sortedLabels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        sortedLabels[idx].split(' ')[0],
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: _brandColor,
              barWidth: 4,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    _brandColor.withOpacity(0.2),
                    _brandColor.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopSalesTile extends StatelessWidget {
  final String shopId;
  final int salesCount;
  final Color brandColor;

  const _ShopSalesTile({
    required this.shopId,
    required this.salesCount,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('shop').doc(shopId).get(),
      builder: (context, snapshot) {
        String shopName = snapshot.hasData
            ? (snapshot.data!['shop_name'] ?? 'Shop')
            : "Loading...";
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ShopDetailReport(shopId: shopId, shopName: shopName),
              ),
            ),
            leading: CircleAvatar(
              backgroundColor: brandColor.withOpacity(0.1),
              child: Icon(LucideIcons.store, color: brandColor, size: 18),
            ),
            title: Text(
              shopName,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: Text("Selected Period: $salesCount Sales"),
            trailing: const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
