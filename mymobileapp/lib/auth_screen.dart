import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

// Main screen with gradient background and custom tab bar
class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                  child: Text(
                    'Somali Dataset',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                // Custom TabBar
                TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3.0, color: Colors.white),
                    insets: EdgeInsets.symmetric(horizontal: 40.0),
                  ),
                  tabs: [
                    Tab(child: Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                    Tab(child: Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                  ],
                ),
                // Animated TabBarView
                Expanded(
                  child: TabBarView(
                    children: [
                      AuthFormContainer(child: LoginForm()),
                      AuthFormContainer(child: SignupForm()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Animated container for the forms
class AuthFormContainer extends StatefulWidget {
  final Widget child;
  const AuthFormContainer({Key? key, required this.child}) : super(key: key);

  @override
  _AuthFormContainerState createState() => _AuthFormContainerState();
}

class _AuthFormContainerState extends State<AuthFormContainer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              elevation: 10.0,
              shadowColor: Colors.black.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper for modern text field decoration
InputDecoration _buildInputDecoration(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.grey.shade600),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: const Color(0xFF1E3A8A), width: 2),
    ),
  );
}

// Login Form Widget (Updated for Username Login)
class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _usernameController,
              decoration: _buildInputDecoration('Username', Icons.person_outline),
              validator: (value) {
                if (value!.isEmpty) return "Please enter your username";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return "Please enter your password";
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (authProvider.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authProvider.error!.replaceAll('Exception: ', ''),
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await authProvider.login(
                          _usernameController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF2563EB),
                elevation: 5,
                shadowColor: Colors.blueAccent.withOpacity(0.4),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// Signup Form Widget (Updated for Username Registration)
class SignupForm extends StatefulWidget {
  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Create Account",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration('Full Name', Icons.person_outline),
              validator: (value) {
                if (value!.isEmpty) return "Please enter your name";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: _buildInputDecoration('Username', Icons.alternate_email),
              validator: (value) {
                if (value!.isEmpty) return "Please enter a username";
                if (value.contains(' ')) return "Username cannot contain spaces";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: _buildInputDecoration('Email', Icons.email_outlined),
              validator: (value) {
                if (value!.isEmpty) return "Please enter your email";
                if (!value.contains('@')) return "Please enter a valid email";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return "Please enter a password";
                if (value.length < 6) return "Password must be at least 6 characters";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: _buildInputDecoration('Confirm Password', Icons.lock_outline).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              validator: (value) {
                if (value != _passwordController.text) return "Passwords do not match";
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (authProvider.error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authProvider.error!.replaceAll('Exception: ', ''),
                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await authProvider.register(
                          _nameController.text.trim(),
                          _usernameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: const Color(0xFF2563EB),
                elevation: 5,
                shadowColor: Colors.blueAccent.withOpacity(0.4),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : const Text('Register', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
