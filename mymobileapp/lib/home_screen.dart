import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'services/dataset_service.dart';
import 'dataset_list_screen.dart';
import 'profile_and_login_page.dart';
import 'upload_dataset_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const primaryBlue = Color(0xFF144BA6);
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeContent(),
      const DatasetListScreen(),
      // Allow all users to upload datasets
      const UploadDatasetScreen(),
      const ProfileAndLoginPage(),
    ];
    
    // Fetch datasets when app starts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DatasetProvider>(context, listen: false).fetchDatasets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.dataset_rounded), label: 'Datasets'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Upload'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
            selectedItemColor: primaryBlue,
            unselectedItemColor: Colors.grey,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 20,
          ),
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  static const primaryBlue = Color(0xFF144BA6);

  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatasetProvider>(
      builder: (context, datasetProvider, _) {
        final datasets = datasetProvider.datasets;
        final isLoading = datasetProvider.isLoading;

        return Scaffold(
          body: SafeArea(
            child: isLoading && datasets.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar
                    SliverAppBar(
                      floating: true,
                      pinned: false,
                      backgroundColor: Colors.white,
                      elevation: 0,
                      title: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: const AssetImage('assets/profile.jpg'),
                            radius: 18,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Somali Dataset',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: primaryBlue,
                                ),
                              ),
                              Text(
                                'Repository',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Content
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Welcome Card
                          _buildWelcomeCard(context),
                          
                          const SizedBox(height: 24),
                          
                          // Dataset Categories
                          _buildCategoriesSection(context),
                          
                          const SizedBox(height: 24),
                          
                          // Featured Dataset
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              'Featured Dataset',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          if (datasets.isNotEmpty)
                            _buildFeaturedDatasetCard(context, datasets[0])
                          else
                            _buildEmptyDatasetCard(),
                            
                          const SizedBox(height: 24),
                          
                          // Recent Datasets
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text(
                                  'Recent Datasets',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  // Navigate to datasets tab
                                  final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                                  if (homeScreenState != null) {
                                    homeScreenState.setState(() {
                                      homeScreenState._currentIndex = 1;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.arrow_forward, size: 16, color: primaryBlue),
                                label: const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Recent datasets grid
                          if (datasets.isNotEmpty)
                            _buildRecentDatasetsGrid(context, datasets)
                          else
                            _buildEmptyDatasetCard(),
                        ]),
                      ),
                    ),
                  ],
                ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final userName = Provider.of<AuthProvider>(context).user?['name'] ?? 'Guest';
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: primaryBlue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: primaryBlue,
                  child: Icon(Icons.waving_hand_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Explore Somali language datasets',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Discover and download high-quality Somali language datasets for research and development.',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to datasets tab
                final homeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                if (homeScreenState != null) {
                  homeScreenState.setState(() {
                    homeScreenState._currentIndex = 1;
                  });
                }
              },
              icon: const Icon(Icons.explore_rounded),
              label: const Text('Explore Datasets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(BuildContext context) {
    final categories = [
      {'title': 'CSV', 'icon': Icons.table_chart_rounded, 'color': Colors.green},
      {'title': 'Excel', 'icon': Icons.grid_on_rounded, 'color': Colors.teal},
      {'title': 'JSON', 'icon': Icons.code_rounded, 'color': Colors.amber},
      {'title': 'Text', 'icon': Icons.text_fields_rounded, 'color': primaryBlue},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(
                title: category['title'] as String,
                icon: category['icon'] as IconData,
                color: category['color'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedDatasetCard(BuildContext context, Dataset dataset) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.dataset_rounded,
                size: 180,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with type and download icon
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          dataset.type.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Title and description
                  Text(
                    dataset.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dataset.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Bottom row with metadata
                  Row(
                    children: [
                      _buildInfoChip(dataset.type, Colors.white),
                      const SizedBox(width: 8),
                      _buildInfoChip(dataset.size, Colors.white),
                      const Spacer(),
                      const Text(
                        "Featured",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Clickable overlay
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to dataset details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Viewing ${dataset.title} details'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRecentDatasetsGrid(BuildContext context, List<Dataset> datasets) {
    final displayDatasets = datasets.length > 4 ? datasets.sublist(0, 4) : datasets;
    
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayDatasets.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return _buildDatasetGridItem(context, displayDatasets[index]);
      },
    );
  }

  Widget _buildDatasetGridItem(BuildContext context, Dataset dataset) {
    final Color typeColor = _getTypeColor(dataset.type);
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to dataset details
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing ${dataset.title} details'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getTypeIcon(dataset.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.more_vert,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Title
              Text(
                dataset.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Description
              Text(
                dataset.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const Spacer(),
              
              // Type and size
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dataset.type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dataset.size,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
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
            Icons.inventory_2_outlined, // Fixed icon name
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

  Color _getTypeColor(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Colors.green;
      case 'excel':
        return Colors.teal;
      case 'json':
        return Colors.amber;
      case 'text':
        return primaryBlue;
      case 'audio':
        return Colors.purple;
      case 'dictionary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'csv':
        return Icons.table_chart_rounded;
      case 'excel':
        return Icons.grid_on_rounded;
      case 'json':
        return Icons.code_rounded;
      case 'text':
        return Icons.description_rounded;
      case 'audio':
        return Icons.headphones_rounded;
      case 'dictionary':
        return Icons.menu_book_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }
} 