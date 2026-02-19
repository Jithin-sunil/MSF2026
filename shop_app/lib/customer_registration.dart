import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomerRegistration extends StatefulWidget {
  final String? preSelectedCoupon; // Receives code from Inventory

  const CustomerRegistration({super.key, this.preSelectedCoupon});

  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  String? _selectedCoupon; 
  bool _isSaving = false;

  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _inputBg = const Color(0xFFF5F7F9);

  @override
  void initState() {
    super.initState();
    // Use the coupon passed from Inventory if available
    _selectedCoupon = widget.preSelectedCoupon;
  }

  // --- SAVE CUSTOMER & CONSUME COUPON ---
  Future<void> _saveCustomer() async {
    if (_selectedCoupon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select a coupon first"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final firestore = FirebaseFirestore.instance;

      try {
        String? shopId = FirebaseAuth.instance.currentUser?.uid;
        if (shopId == null) throw "Authentication error";

        // Use a Batch to ensure both actions happen together
        WriteBatch batch = firestore.batch();

        // 1. Add Customer record
        DocumentReference customerRef = firestore.collection('customers').doc();
        batch.set(customerRef, {
          'coupon_code': _selectedCoupon,
          'name': _nameController.text.trim(),
          'contact': _contactController.text.trim(),
          'shop_id': shopId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 2. Mark Coupon as used in assigned_coupons
        // Note: The document ID in assigned_coupons must be the coupon code for this to work
        DocumentReference couponRef = firestore
            .collection('assigned_coupons')
            .doc(_selectedCoupon);
        batch.update(couponRef, {'status': 'used'});

        await batch.commit();

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member Registered Successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Go back to inventory/previous page
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      appBar: AppBar(
        backgroundColor: _bgPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Register Member',
          style: GoogleFonts.poppins(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Details',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 30),

              // --- COUPON DISPLAY BOX (Fixed Design) ---
              Text(
                'Assigned Coupon Code',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: _brandColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _brandColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.ticket, color: Color(0xFF009ADE), size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedCoupon ?? "No Coupon Selected",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _brandColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- CUSTOMER NAME FIELD ---
              _buildTextField(
                controller: _nameController,
                label: 'Customer Name',
                hint: 'Enter full name',
                icon: LucideIcons.user,
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 20),

              // --- CONTACT NUMBER FIELD ---
              _buildTextField(
                controller: _contactController,
                label: 'Contact Number',
                hint: '10 digit mobile number',
                icon: LucideIcons.phone,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.length < 10 ? 'Enter valid contact' : null,
              ),

              const SizedBox(height: 50),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'COMPLETE REGISTRATION',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to keep the UI exactly as per your previous request
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey, size: 20),
            filled: true,
            fillColor: _inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}