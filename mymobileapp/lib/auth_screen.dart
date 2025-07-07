import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Somali Dataset Repository'),
          bottom: const TabBar(
            labelColor: Color(0xFF144BA6),
            unselectedLabelColor: Colors.black54,
            indicatorColor: Color(0xFF144BA6),
            tabs: [
              Tab(text: 'Login'),
              Tab(text: 'Register'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            LoginForm(),
            SignupForm(),
          ],
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
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
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
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
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authProvider.error!.replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await authProvider.login(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF144BA6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(1);
                },
                child: const Text("Don't have an account? Register"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupForm extends StatefulWidget {
  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: true);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value!.isEmpty) return "Please enter your name";
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
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
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return "Please enter a password";
                if (value.length < 6) {
                  return "Password must be at least 6 characters";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) return "Please confirm your password";
                if (value != _passwordController.text) {
                  return "Passwords do not match";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (authProvider.error != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authProvider.error!.replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: authProvider.isLoading
                  ? null
                  : () async {
                      if (_formKey.currentState!.validate()) {
                        await authProvider.register(
                          _nameController.text.trim(),
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: const Color(0xFF144BA6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: authProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Register', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  DefaultTabController.of(context).animateTo(0);
                },
                child: const Text("Already have an account? Login"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
