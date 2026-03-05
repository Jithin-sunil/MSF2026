import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shop_app/homepage.dart';
import 'package:shop_app/login.dart';

class ShopRegistration extends StatefulWidget {
  const ShopRegistration({super.key});

  @override
  State<ShopRegistration> createState() => _ShopRegistrationState();
}

class _ShopRegistrationState extends State<ShopRegistration> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController(); // Now Optional
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  bool obscureText = true;
  bool _isLoading = false;
  bool _isAccepted = false; // Track terms acceptance

  AutovalidateMode _validateMode = AutovalidateMode.disabled;
  String? selectedShopType;

  // --- BRAND COLORS ---
  final Color _brandColor = const Color(0xFF009ADE);
  final Color _bgPrimary = Colors.white;
  final Color _inputBg = const Color(0xFFF5F7F9);
  final Color _iconColor = const Color(0xFF9E9E9E);

  @override
  void dispose() {
    nameController.dispose();
    shopNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    contactController.dispose();
    super.dispose();
  }

  // --- FULL VALIDATION LOGIC ---

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) return "Owner Name is required";
    if (value.length < 2) return "Name must be at least 2 letters";
    if (!RegExp(r'^[A-Z][a-zA-Z\s]*$').hasMatch(value)) {
      return "Start with Capital (only letters & spaces allowed)";
    }
    return null;
  }

  String? _validateShopName(String? value) {
    if (value == null || value.isEmpty) return "Shop Name is required";
    if (value.length < 2) return "Shop name must be at least 2 characters";
    if (!RegExp(r'^[A-Z][a-zA-Z\s&]*$').hasMatch(value)) {
      return "Start with Capital (letters, spaces & '&' only)";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    // UPDATED: Email is now optional
    if (value == null || value.isEmpty) return null; 
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Enter a valid email ID";
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return "Contact Number is required";
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return "Enter a valid 10-digit number starting with 6-9";
    }
    return null;
  }

  // --- UPDATED DIALOG WITH COUPON TERMS ---
  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Terms & Conditions",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _sectionHeader("I. Merchant Agreement"),
                  _termsItem(1, "I voluntarily participate in the Scratch and Win Coupon Scheme of the Muvattupuzha Shopping Festival."),
                  _termsItem(2, "I am fully aware of all details regarding the Shopping Festival."),
                  _termsItem(3, "I agree to distribute coupons for free to customers."),
                  _termsItem(4, "I agree to record winner details in the mobile app provided by the Association in real-time."),
                  _termsItem(5, "I agree to provide cash discounts to customers immediately at my establishment."),
                  _termsItem(6, "I shall abide by all decisions taken by the Muvattupuzha Merchants’ Association."),
                  const SizedBox(height: 20),
                  _sectionHeader("II. Coupon Terms & Conditions"),
                  _termsItem(1, "These coupons are for free distribution to customers only."),
                  _termsItem(2, "The validity period is from February 15, 2026, to April 15, 2026."),
                  _termsItem(3, "Coupons are non-transferable; any transfer renders the coupon void."),
                  _termsItem(4, "Coupons will not be issued in the names of multiple individuals."),
                  _termsItem(5, "Cash discounts must be claimed immediately from the respective shops."),
                  _termsItem(6, "All prizes other than cash discounts shall be issued from the Muvattupuzha Merchants' Association office."),
                  _termsItem(7, "Prizes must be claimed within 3 working days of receiving the winning coupon."),
                  _termsItem(8, "For issues regarding gifted products, customers must contact the respective shop owner."),
                  _termsItem(9, "The Association is not responsible for damages occurring to glass products."),
                  _termsItem(10, "All disputes regarding the Shopping Festival are subject to the jurisdiction of the courts in Muvattupuzha."),
                  _termsItem(11, "Images on the coupons are for illustrative purposes only."),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                   setState(() => _isAccepted = true);
                   Navigator.pop(context);
                },
                child: const Text("I ACCEPT ALL TERMS", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: _brandColor,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _termsItem(int index, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$index. ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              body,
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[800], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegistration() async {
    FocusScope.of(context).unfocus();
    setState(() => _validateMode = AutovalidateMode.onUserInteraction);

    if (!_formKey.currentState!.validate()) return;
    if (!_isAccepted) {
      _showError('Please accept the Terms and Conditions to proceed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // LOGIC: Use provided email OR create virtual email from phone
      String finalAuthEmail = emailController.text.trim().isNotEmpty 
          ? emailController.text.trim() 
          : "${contactController.text.trim()}@msf2026.com";

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: finalAuthEmail,
            password: passwordController.text.trim(),
          );

      User? user = userCredential.user;

      if (user != null) {
        // SAVING EVERYTHING TO FIRESTORE
        final dbTask = FirebaseFirestore.instance
            .collection('shop')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'owner_name': nameController.text.trim(),
              'shop_name': shopNameController.text.trim(),
              'email': emailController.text.trim().isEmpty ? null : emailController.text.trim(),
              'login_id': finalAuthEmail, 
              'shop_type': selectedShopType,
              'contact': contactController.text.trim(),
              'role': 'shop_owner',
              'status': 'pending',
              'password': passwordController.text.trim(), // Storing raw password
              'createdAt': FieldValue.serverTimestamp(),
            });

        final nameTask = user.updateDisplayName(shopNameController.text.trim());

        await Future.wait([dbTask, nameTask]);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration Successful! Welcome.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Registration failed');
    } catch (e) {
      _showError('An unexpected error occurred');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _validateMode,
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  height: 100, width: 100,
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                  child: Image.asset(
                    'assets/msf2026logo.png',
                    errorBuilder: (c, e, s) => Icon(LucideIcons.store, size: 50, color: _brandColor),
                  ),
                ),
                const SizedBox(height: 20),
                Text('MSF2026 Registration', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 30),

                _buildTextField(controller: nameController, label: 'Owner Full Name', icon: LucideIcons.user, validator: _validateFullName),
                const SizedBox(height: 16),
                _buildTextField(controller: shopNameController, label: 'Shop Name', icon: LucideIcons.store, validator: _validateShopName),
                const SizedBox(height: 16),

                _buildShopTypeDropdown(),
                const SizedBox(height: 16),

                _buildTextField(controller: contactController, label: 'Contact Number', icon: LucideIcons.phone, inputType: TextInputType.phone, validator: _validatePhone),
                const SizedBox(height: 16),

                _buildTextField(controller: emailController, label: 'Email Address (Optional)', icon: LucideIcons.mail, inputType: TextInputType.emailAddress, validator: _validateEmail),
                const SizedBox(height: 16),

                _buildPasswordField(),
                const SizedBox(height: 20),

                Row(
                  children: [
                    SizedBox(
                      height: 24, width: 24,
                      child: Checkbox(value: _isAccepted, activeColor: _brandColor, onChanged: (v) => setState(() => _isAccepted = v!)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTermsDialog,
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                            children: [
                              const TextSpan(text: "I agree to the "),
                              TextSpan(text: "Terms and Conditions", style: TextStyle(color: _brandColor, fontWeight: FontWeight.bold)),
                              const TextSpan(text: " of MSF 2026."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity, height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _brandColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _isLoading ? null : _handleRegistration,
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER SHOP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                  child: Text('Already registered? Login Now', style: GoogleFonts.poppins(color: _brandColor, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType inputType = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(controller: controller, keyboardType: inputType, decoration: _inputDecoration(label, icon), validator: validator);
  }

  Widget _buildShopTypeDropdown() {
    return StreamBuilder<QuerySnapshot>(
      // UPDATED: Points to 'shop_types' collection as established in Admin App
      stream: FirebaseFirestore.instance.collection('types').snapshots(),
      builder: (context, snapshot) {
        List<DropdownMenuItem<String>> typeItems = [];
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            String name = doc['type_name'];
            typeItems.add(DropdownMenuItem(value: name, child: Text(name)));
          }
        }
        return DropdownButtonFormField<String>(
          value: selectedShopType,
          decoration: _inputDecoration("Select Shop Type", LucideIcons.tag),
          items: typeItems,
          onChanged: (val) => setState(() => selectedShopType = val),
          validator: (v) => v == null ? "Please select shop type" : null,
        );
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: obscureText,
      decoration: _inputDecoration('Password', LucideIcons.lock).copyWith(
        suffixIcon: IconButton(icon: Icon(obscureText ? LucideIcons.eyeOff : LucideIcons.eye, color: _iconColor, size: 20), onPressed: () => setState(() => obscureText = !obscureText)),
      ),
      validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: _iconColor, size: 20),
      filled: true, fillColor: _inputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _brandColor, width: 1.5)),
    );
  }
}