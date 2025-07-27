import 'package:flutter/material.dart';
import 'auth_screen.dart';

class OnboardingScreenModern extends StatefulWidget {
  const OnboardingScreenModern({super.key});

  @override
  State<OnboardingScreenModern> createState() => _OnboardingScreenModernState();
}

class _OnboardingScreenModernState extends State<OnboardingScreenModern> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      image: 'https://machinelearningmodels.org/wp-content/uploads/2023/09/142_resultado.webp',
      title: 'Access Somali Datasets',
      subtitle: 'Comprehensive language resources',
      color: const Color(0xFF3D73DD),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      image: 'https://vitalflux.com/wp-content/uploads/2021/02/dataset_publicly_available_free_machine_learning.png',
      title: 'Powerful Search Tools',
      subtitle: 'Find exactly what you need quickly',
      color: const Color(0xFF56AB91),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      image: 'https://www.zfort.com/images/blog/og/6384158f7c930_Machine%20Learning%20Dataset.png',
      title: 'Download & Share',
      subtitle: 'Use resources in your projects',
      color: const Color(0xFFF7B84B),
      textColor: Colors.black87,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.ease,
      );
    } else {
      // Navigate to auth screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  void _skipOnboarding() {
    // Navigate to auth screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen background images
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Image.network(
                _pages[index].image,
                fit: BoxFit.fill,
                width: double.infinity,
                height: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.error, color: Colors.red, size: 50),
                  );
                },
              );
            },
          ),

          // Skip Button
          Positioned(
            top: 40,
            right: 20,
            child: _currentPage != _pages.length - 1
                ? TextButton(
                    onPressed: _skipOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: _pages[_currentPage].textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Bottom content sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min, // Important for bottom sheet
                children: [
                  // Title and subtitle
                  Text(
                    _pages[_currentPage].title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _pages[_currentPage].subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32), // Spacing

                  // Page indicator and next button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator dots
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? _pages[_currentPage].color
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      ),

                      // Next/Get Started button
                      InkWell(
                        onTap: _onNextPage,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _pages[_currentPage].color,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage]
                                    .color
                                    .withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              color: _pages[_currentPage].textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageData {
  final String image;
  final String title;
  final String subtitle;
  final Color color;
  final Color textColor;

  OnboardingPageData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
  });
} 