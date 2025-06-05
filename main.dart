import 'dart:ui'; // Required for blur effect
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quickshieldback/sos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController guardianController = TextEditingController();

  // Function to request permission and get location
  Future<void> requestLocationAndLogin() async {
    PermissionStatus status = await Permission.location.request();

    if (status.isGranted) {
      print("✅ Location permission granted!");
      _getCurrentLocation();
    } else if (status.isDenied) {
      print("❌ Location permission denied!");
      _showPermissionDialog();
    } else if (status.isPermanentlyDenied) {
      print("⚠️ Location permission permanently denied! Opening settings...");
      _showPermissionDialog();
    }
  }

  // Function to get the current location and save to Firestore
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("❌ Location services are disabled!");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    print("📍 Location fetched: ${position.latitude}, ${position.longitude}");

    // Save user data to Firestore and navigate to SOSPage
    _saveUserData(position.latitude, position.longitude);
  }

  // Function to save user details + location to Firestore
  void _saveUserData(double latitude, double longitude) {
    FirebaseFirestore.instance.collection('users').add({
      'email': emailController.text.trim(),
      'password': passwordController.text.trim(),
      'mobile': mobileController.text.trim(),
      'guardian': guardianController.text.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.now(),
    }).then((_) {
      _showSuccess("✅ Login Successful! Data Saved.");
      // Navigate to SOS Page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SOSHomePage(guardianNumber: guardianController.text.trim()),
        ),
      );
    }).catchError((error) {
      _showError("⚠️ Failed to save data: $error");
    });
  }

  // Show alert dialog for permission issues
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text("Location access is needed. Enable it in settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  // Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
    ));
  }

  // Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/women_login.png', // Your image path
              fit: BoxFit.cover,
            ),
          ),
          // Semi-transparent overlay for readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3), // Adjust transparency
            ),
          ),
          // Glassmorphic Effect for Form
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Adds blur effect
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4), // Adjust opacity for better transparency
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.2)), // Subtle border
                    ),
                    child: Form(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildInputField("Email ID", emailController, TextInputType.emailAddress, false),
                          _buildInputField("Password", passwordController, TextInputType.text, true),
                          _buildInputField("Mobile No", mobileController, TextInputType.phone, false),
                          _buildInputField("Guardian's No", guardianController, TextInputType.phone, false),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: requestLocationAndLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent, // Button color
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom method to build text fields with placeholders
  Widget _buildInputField(String hintText, TextEditingController controller, TextInputType keyboardType, bool isObscure) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isObscure,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hintText, // Placeholder text
          filled: true,
          fillColor: Colors.white.withOpacity(0.3), // More transparent background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // Remove default border
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        ),
      ),
    );
  }
}

// Placeholder for SOSPage (Create this in another file if needed)
class SOSPage extends StatelessWidget {
  final String guardianNumber;
  const SOSPage({super.key, required this.guardianNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SOS Page")),
      body: Center(
        child: Text("Guardian Contact: $guardianNumber"),
      ),
    );
  }
}
