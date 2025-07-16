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
      image: 'https://cdn.dribbble.com/users/1997192/screenshots/15684224/media/1e3141f5c3e0508f4bbcb41ab8df78e9.png',
      title: 'Access Somali Datasets',
      subtitle: 'Comprehensive language resources',
      color: const Color(0xFF3D73DD),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      image: 'https://cdn.dribbble.com/users/1997192/screenshots/15649878/media/fb90ad5d39182c038643abd1c6cd1358.png',
      title: 'Powerful Search Tools',
      subtitle: 'Find exactly what you need quickly',
      color: const Color(0xFF56AB91),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      image: 'https://cdn.dribbble.com/users/1997192/screenshots/15641160/media/3b8902debf9ca8c5181eb1e155a602df.png',
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background color that changes with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: _pages[_currentPage].color,
            child: Container(),
          ),
          
          // Main content
          Column(
            children: [
              // Upper section with image
              Expanded(
                flex: 3,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _pages[index].color,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Skip button
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40, right: 20),
                              child: index != _pages.length - 1
                                  ? TextButton(
                                      onPressed: _skipOnboarding,
                                      child: Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: _pages[index].textColor,
                                          fontSize: 16,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          
                          // Image
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Image.network(
                                _pages[index].image,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: _pages[index].textColor,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                    color: _pages[index].textColor.withOpacity(0.5),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom white section with text and controls
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Title and subtitle
                        Column(
                          children: [
                            Text(
                              _pages[_currentPage].title,
                              style: const TextStyle(
                                fontSize: 28,
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
                          ],
                        ),
                        
                        // Page indicator and next button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Page indicator dots
                            Row(
                              children: List.generate(
                                _pages.length,
                                (index) => Container(
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
                                      color: _pages[_currentPage].color.withOpacity(0.4),
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
              ),
            ],
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