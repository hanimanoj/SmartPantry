import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  bool hasUppercase = false;
  bool hasNumber = false;
  bool hasSpecialChar = false;
  bool hasMinLength = false;

  void checkPassword(String value) {
    setState(() {
      hasUppercase = value.contains(RegExp(r'[A-Z]'));
      hasNumber = value.contains(RegExp(r'[0-9]'));
      hasSpecialChar = value.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
      hasMinLength = value.length >= 6;
    });
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!hasUppercase || !hasNumber || !hasSpecialChar || !hasMinLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password does not meet requirements")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Create the user
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Save the name into FirebaseAuth profile
      await credential.user?.updateDisplayName(nameController.text.trim());

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context); // back to login page
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      String message;
      if (e.code == 'email-already-in-use') {
        message = "This email already exists";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email";
      } else {
        message = e.message ?? "Register failed";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget buildCheck(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF4CAD73);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Register"),
        backgroundColor: primaryGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: "Enter your Name",
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter full name" : null,
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  hintText: "Enter your Email",
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter email";
                  if (!value.contains("@") || !value.contains(".")) return "Invalid email";
                  return null;
                },
              ),

              const SizedBox(height: 15),

              TextFormField(
                controller: passwordController,
                obscureText: hidePassword,
                onChanged: checkPassword,
                decoration: InputDecoration(
                  hintText: "Enter your Password",
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? "Please enter password" : null,
              ),

              const SizedBox(height: 15),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildCheck("At least 6 characters", hasMinLength),
                  buildCheck("Contains uppercase letter", hasUppercase),
                  buildCheck("Contains number", hasNumber),
                  buildCheck("Contains special character", hasSpecialChar),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : register,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("REGISTER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
