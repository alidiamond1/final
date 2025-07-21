import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _registerNameController = TextEditingController();
  final TextEditingController _registerUsernameController =
      TextEditingController();
  final TextEditingController _registerConfirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoginView = true; // Toggle between login and register views

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isLoginView = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerNameController.dispose();
    _registerUsernameController.dispose();
    _registerConfirmPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Handle login
  Future<void> _login() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Call login method without trying to get a return value
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Check if authentication was successful
        if (authProvider.isAuthenticated && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Login failed. Check your credentials."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // Handle registration
  Future<void> _register() async {
    if (_registerFormKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Call register with all 4 required parameters
        await authProvider.register(
          _registerNameController.text.trim(),
          _registerUsernameController.text.trim(),
          _registerEmailController.text.trim(),
          _registerPasswordController.text,
        );

        // Check if authentication was successful after registration
        if (authProvider.isAuthenticated && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else if (mounted && authProvider.error == null) {
          // If no error but not authenticated, registration was successful but login wasn't automatic
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Registration successful! Please log in."),
              backgroundColor: Colors.green,
            ),
          );
          _tabController.animateTo(0); // Switch to login tab
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Registration failed: ${authProvider.error ?? 'Unknown error'}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: ${e.toString()}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF144BA6), Color(0xFF0A2A66)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // App Logo/Image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App Title
                  const Text(
                    'Somali Dataset Repository',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Auth Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tab bar for Login/Register
                        TabBar(
                          controller: _tabController,
                          labelColor: const Color(0xFF144BA6),
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: const Color(0xFF144BA6),
                          indicatorWeight: 3,
                          tabs: const [
                            Tab(text: 'Login'),
                            Tab(text: 'Register'),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tab content with dynamic height
                        SizedBox(
                          // Use a reasonable height that can fit the content
                          height: _isLoginView ? 350 : 550,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Login Form - wrapped in SingleChildScrollView
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Form(
                                    key: _loginFormKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Email field
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: _inputDecoration(
                                              'Username', Icons.person),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your username';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Password field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          decoration: _inputDecoration(
                                            'Password',
                                            Icons.lock,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible =
                                                      !_isPasswordVisible;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 8),

                                        // // Forgot password link
                                        // Align(
                                        //   alignment: Alignment.centerRight,
                                        //   child: TextButton(
                                        //     onPressed: () {
                                        //       // Handle forgot password
                                        //     },
                                        //     style: TextButton.styleFrom(
                                        //       foregroundColor: const Color(0xFF144BA6),
                                        //     ),
                                        //     child: const Text('Forgot Password?'),
                                        //   ),
                                        // ),

                                        const SizedBox(height: 24),

                                        // Login button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _login,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF144BA6),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Login',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Switch to register account
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Don't have an account? ",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _tabController.animateTo(
                                                    1); // Switch to register tab
                                              },
                                              child: const Text(
                                                "Register",
                                                style: TextStyle(
                                                  color: Color(0xFF144BA6),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Register Form
                              SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0),
                                  child: Form(
                                    key: _registerFormKey,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Name field
                                        TextFormField(
                                          controller: _registerNameController,
                                          decoration: _inputDecoration(
                                              'Full Name', Icons.person),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your name';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Username field
                                        TextFormField(
                                          controller:
                                              _registerUsernameController,
                                          decoration: _inputDecoration(
                                              'Username', Icons.account_circle),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a username';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Email field
                                        TextFormField(
                                          controller: _registerEmailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          decoration: _inputDecoration(
                                              'Email', Icons.email),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter your email';
                                            }
                                            if (!RegExp(
                                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                .hasMatch(value)) {
                                              return 'Please enter a valid email address';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Password field
                                        TextFormField(
                                          controller:
                                              _registerPasswordController,
                                          obscureText: !_isPasswordVisible,
                                          decoration: _inputDecoration(
                                            'Password',
                                            Icons.lock,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isPasswordVisible =
                                                      !_isPasswordVisible;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please enter a password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 16),

                                        // Confirm Password field
                                        TextFormField(
                                          controller:
                                              _registerConfirmPasswordController,
                                          obscureText: !_isConfirmPasswordVisible,
                                          decoration: _inputDecoration(
                                            'Confirm Password',
                                            Icons.lock,
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isConfirmPasswordVisible
                                                    ? Icons.visibility
                                                    : Icons.visibility_off,
                                                color: Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _isConfirmPasswordVisible =
                                                      !_isConfirmPasswordVisible;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please confirm your password';
                                            }
                                            if (value !=
                                                _registerPasswordController
                                                    .text) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 24),

                                        // Register button
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _register,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFF144BA6),
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 12),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Register',
                                                    style:
                                                        TextStyle(fontSize: 16),
                                                  ),
                                          ),
                                        ),

                                        const SizedBox(height: 16),

                                        // Switch to login account
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Already have an account? ",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                _tabController.animateTo(
                                                    0); // Switch to login tab
                                              },
                                              child: const Text(
                                                "Login",
                                                style: TextStyle(
                                                  color: Color(0xFF144BA6),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create consistent input decoration
  InputDecoration _inputDecoration(String label, IconData icon,
      {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Color(0xFF144BA6)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: Colors.red),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
