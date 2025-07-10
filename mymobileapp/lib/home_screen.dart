import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'services/dataset_service.dart';
import 'dataset_list_screen.dart';
import 'profile_screen.dart';
import 'upload_dataset_screen.dart';
import 'services/auth_service.dart';
import 'download_manager.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

// Main Screen Widget that holds the Bottom Navigation Bar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const DatasetListScreen(),
      const UploadDatasetScreen(),
      const ProfileScreen(),
    ];

    // Fetch datasets once after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatasetProvider>(context, listen: false).fetchDatasets();
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of each page when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildGoogleNavBar(),
    );
  }

  Widget _buildGoogleNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: Colors.black.withOpacity(.1),
          )
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: 8,
            activeColor: Colors.white,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: const Color(0xFF2C5282), // Same deep blue color
            color: Colors.grey.shade600,
            tabs: const [
              GButton(
                icon: Icons.home_filled,
                text: 'Home',
              ),
              GButton(
                icon: Icons.storage_rounded,
                text: 'Datasets',
              ),
              GButton(
                icon: Icons.cloud_upload_rounded,
                text: 'Upload',
              ),
              GButton(
                icon: Icons.person_2_rounded,
                text: 'Profile',
              ),
            ],
            selectedIndex: _currentIndex,
            onTabChange: (index) {
              _onTabTapped(index);
            },
          ),
        ),
      ),
    );
  }
}

// --- Home Content Widget (The actual home screen UI) --- //
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final datasetProvider = Provider.of<DatasetProvider>(context);
    final datasets = datasetProvider.datasets;
    final isLoading = datasetProvider.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: isLoading && datasets.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(context),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          _AnimatedFadeSlide(controller: _animationController, child: _buildSearchBar()),
                          const SizedBox(height: 24),
                          _AnimatedFadeSlide(controller: _animationController, delay: 0.1, child: _buildSectionTitle('Categories')),
                          const SizedBox(height: 16),
                          _AnimatedFadeSlide(controller: _animationController, delay: 0.2, child: _buildCategoriesSection()),
                          const SizedBox(height: 24),
                          if (datasets.isNotEmpty)
                            _AnimatedFadeSlide(controller: _animationController, delay: 0.3, child: _buildSectionTitle('Featured Dataset')),
                          if (datasets.isNotEmpty)
                            const SizedBox(height: 16),
                          if (datasets.isNotEmpty)
                            _AnimatedFadeSlide(controller: _animationController, delay: 0.4, child: _buildFeaturedDatasetCard(context, datasets.first))
                          else if (!isLoading)
                            _buildEmptyDatasetCard(),
                          if (datasets.isNotEmpty)
                            const SizedBox(height: 24),
                          if (datasets.length > 1)
                            _AnimatedFadeSlide(
                              controller: _animationController,
                              delay: 0.5,
                              child: _buildSectionTitle(
                                'Recent Datasets',
                                showViewAll: datasets.length > 5, // 1 featured + 4 recent
                                onViewAllTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const DatasetListScreen()));
                                },
                              ),
                              
                            ),
                          if (datasets.length > 1)
                            const SizedBox(height: 16),
                          if (datasets.length > 1)
                            _AnimatedFadeSlide(
                              controller: _animationController,
                              delay: 0.6,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.85,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: datasets.skip(1).take(4).length,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  return _buildDatasetGridItem(context, datasets.skip(1).toList()[index]);
                                },
                              ),
                            )
                          else if (datasets.isEmpty && isLoading)
                            const Center(child: CircularProgressIndicator()),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- UI Helper Methods --- //

  Widget _buildHeader(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userName = user?['name']?.split(' ').first ?? 'User';
    final imageString = user?['profileImage'] as String?;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      automaticallyImplyLeading: false,
      title: _AnimatedFadeSlide(
        controller: _animationController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, $userName 👋', style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('Ready to explore some datasets?', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            key: authProvider.profileImageKey, // Force rebuild when image changes
            radius: 22,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _getImageProvider(imageString),
            child: imageString == null
                ? const Icon(
                    Icons.person,
                    size: 28,
                    color: Colors.grey,
                  )
                : null,
          ),
        ),
      ],
    );
  }

  ImageProvider _getImageProvider(String? imageString) {
    if (imageString == null || imageString.isEmpty) {
      return const AssetImage('assets/profile.jpg'); // Default image
    }

    if (imageString.startsWith('http')) {
      // Handle regular URL
      return NetworkImage(imageString);
    } else if (imageString.startsWith('data:image')) {
      // Handle Base64 data URI
      try {
        final parts = imageString.split(',');
        if (parts.length == 2) {
          final bytes = base64Decode(parts[1]);
          return MemoryImage(bytes);
        }
      } catch (e) {
        print('Error decoding Base64 image on home screen: $e');
        return const AssetImage('assets/profile.jpg'); // Fallback on error
      }
    }

    // Fallback for any other case, including old file paths
    return const AssetImage('assets/profile.jpg');
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for datasets...',
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

    Widget _buildSectionTitle(String title, {bool showViewAll = false, VoidCallback? onViewAllTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Tani waxay kala fogaynaysaa labada qoraal
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (showViewAll)
          InkWell(
            onTap: onViewAllTap, // Halkan ayuu ka dhacayaa tagitaanka shaashadda kale
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF2C5282),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    final datasets = Provider.of<DatasetProvider>(context).datasets;
    final categories = datasets.map((d) => d.fileType).toSet().toList();

    if (categories.isEmpty) {
      return const Center(child: Text('No categories available.'));
    }

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final categoryTitle = categories[index];
          return _buildCategoryCard(
            title: categoryTitle,
            icon: _getTypeIcon(categoryTitle),
            color: _getTypeColor(categoryTitle),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard({required String title, required IconData icon, required Color color}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFeaturedDatasetCard(BuildContext context, Dataset dataset) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
               _showDatasetDetails(context, dataset);
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dataset.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 5, color: Colors.black54)])),
                  const SizedBox(height: 8),
                  Text(dataset.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _infoChip(Icons.folder_zip_rounded, dataset.fileType.toUpperCase()),
                      const SizedBox(width: 8),
                      _infoChip(Icons.cloud_download_rounded, '${(dataset.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB'),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatasetGridItem(BuildContext context, Dataset dataset) {
    final typeColor = _getTypeColor(dataset.fileType);
    final typeIcon = _getTypeIcon(dataset.fileType);

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showDatasetDetails(context, dataset);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 24),
              ),
              const Spacer(),
              Text(
                dataset.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                dataset.fileType.toUpperCase(),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDatasetCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No datasets available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new datasets',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'csv': return Colors.green.shade400;
      case 'excel': return Colors.teal.shade400;
      case 'json': return Colors.amber.shade400;
      case 'text': return Colors.blue.shade400;
      case 'image': return Colors.orange.shade400;
      case 'images': return Colors.orange.shade400;
      case 'audio': return Colors.purple.shade400;
      case 'video': return Colors.red.shade400;
      case 'dictionary': return Colors.brown.shade400;
      default: return Colors.grey.shade400;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'csv': return Icons.table_chart_rounded;
      case 'excel': return Icons.grid_on_rounded;
      case 'json': return Icons.code_rounded;
      case 'text': return Icons.text_fields_rounded;
      
      default: return Icons.insert_drive_file_rounded;
    }
  }

  void _showDatasetDetails(BuildContext context, Dataset dataset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    dataset.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      dataset.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Dataset Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard('Type', dataset.fileType, Icons.category),
                  _buildDetailCard('Size', '${(dataset.sizeInBytes / 1024 / 1024).toStringAsFixed(2)} MB', Icons.data_usage),
                  if (dataset.createdAt != null)
                    _buildDetailCard('Added', _formatDate(dataset.createdAt!), Icons.calendar_today),
                  _buildDetailCard('ID', dataset.id, Icons.fingerprint),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DownloadManager(context).buildDownloadButton(dataset),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2C5282), size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _infoChip(IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Animation Widget --- //
class _AnimatedFadeSlide extends StatelessWidget {
  final AnimationController controller;
  final Widget child;
  final double delay;

  const _AnimatedFadeSlide({required this.controller, required this.child, this.delay = 0.0});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final animation = CurvedAnimation(
          parent: controller,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}