import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '/firebase_options.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Pages (only one dashboard)
import '../pages/dashboard_page.dart';

// Widgets
import '../widgets/user_badge.dart';
import '../widgets/info_card.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _selectedRole;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  // 🔑 Login logic
  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a role before logging in")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("No role assigned. Contact admin.");
      }

      String role = userDoc["role"];

      // ✅ Check if selected role matches Firestore role
      if (role != _selectedRole) {
        throw Exception("Role mismatch. Please login with correct role.");
      }

      _navigateToDashboard(role);
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 🔀 Navigate to single dynamic dashboard
  void _navigateToDashboard(String userType) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DashboardPage(userRole: userType),
      ),
    );
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Forgot Password flow (not implemented)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 800;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1a2a6c), Color(0xFFb21f1f), Color(0xFFfdbb2d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Container(
                width: isMobile ? double.infinity : 1200,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 30,
                        offset: Offset(0, 10))
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      color: const Color(0xFF1a2a6c),
                      width: double.infinity,
                      child: Column(
                        children: const [
                          Text(
                            "Dedan Kimathi University of Technology",
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFfdbb2d)),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Dekut Security System",
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: isMobile
                          ? SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildLoginSection(isMobile),
                                  _buildInfoSection(isMobile),
                                ],
                              ),
                            )
                          : Row(
                              children: [
                                Expanded(
                                    flex: 35,
                                    child: _buildLoginSection(isMobile)),
                                Expanded(
                                    flex: 65,
                                    child: _buildInfoSection(isMobile)),
                              ],
                            ),
                    ),

                    // Footer
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF1a2a6c),
                      padding: const EdgeInsets.all(15),
                      child: const Text(
                        "© 2025 SafeCampus Incident Reporting System | For emergency, call: 0741 504 278 / 07899 586 630",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Login Form Section
  Widget _buildLoginSection(bool isMobile) {
    return Container(
      color: const Color(0xFF2c3e50),
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text(
              "Welcome Back Please Login",
              style: TextStyle(
                  fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Secure access for authorized users only",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 30),

            // Email
            TextFormField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF34495e),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter your email" : null,
            ),
            const SizedBox(height: 20),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF34495e),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter your password" : null,
            ),
            const SizedBox(height: 40),

            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: const Color(0xFFfdbb2d),
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                    ),
                    const Text(
                      "Remember Me",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _forgotPassword,
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Color(0xFFfdbb2d),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFfdbb2d),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _selectedRole == null ? null : _login,
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(const Color(0xFFfdbb2d)),
                        foregroundColor:
                            MaterialStateProperty.all(const Color(0xFF1a2a6c)),
                        padding: MaterialStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 15)),
                      ),
                      child: const Text(
                        "Login",
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Info Section with Role Badges
  Widget _buildInfoSection(bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(30),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Report Incidents Safely and Efficiently",
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1a2a6c)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Role selection badges
            Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                UserBadge(
                  icon: Icons.admin_panel_settings,
                  label: "Administrator",
                                    isSelected: _selectedRole == "admin",
                  onTap: () => setState(() => _selectedRole = "admin"),
                ),
                UserBadge(
                  icon: Icons.school,
                  label: "Student",
                  isSelected: _selectedRole == "student",
                  onTap: () => setState(() => _selectedRole = "student"),
                ),
                UserBadge(
                  icon: Icons.work,
                  label: "Staff",
                  isSelected: _selectedRole == "staff",
                  onTap: () => setState(() => _selectedRole = "staff"),
                ),
                UserBadge(
                  icon: Icons.security,
                  label: "Security",
                  isSelected: _selectedRole == "security",
                  onTap: () => setState(() => _selectedRole = "security"),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Info Cards
            isMobile
                ? Column(
                    children: [
                      InfoCard(
                        title: "How to Report",
                        items: [
                          "Login with your credentials",
                          "Select incident type and location",
                          "Provide detailed description",
                          "Upload supporting evidence",
                          "Submit for review",
                        ],
                      ),
                      const SizedBox(height: 20),
                      InfoCard(
                        title: "Incident Types",
                        items: [
                          "Safety hazards",
                          "Security breaches",
                          "Theft or property damage",
                          "Harassment issues",
                          "Emergency situations",
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoCard(
                        title: "How to Report",
                        items: [
                          "Login with your credentials",
                          "Select incident type and location",
                          "Provide detailed description",
                          "Upload supporting evidence",
                          "Submit for review",
                        ],
                      ),
                      const SizedBox(width: 20),
                      InfoCard(
                        title: "Incident Types",
                        items: [
                          "Safety hazards",
                          "Security breaches",
                          "Theft or property damage",
                          "Harassment issues",
                          "Emergency situations",
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
