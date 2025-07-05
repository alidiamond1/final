import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/dataset_provider.dart';
import 'services/dataset_service.dart';
import 'download_manager.dart';
import 'upload_dataset_screen.dart';


class DatasetListScreen extends StatefulWidget {
  const DatasetListScreen({super.key});

  @override
  State<DatasetListScreen> createState() => _DatasetListScreenState();
}

class _DatasetListScreenState extends State<DatasetListScreen> {
  static const Color primaryBlue = Color(0xFF144BA6);
  final TextEditingController _searchController = TextEditingController();
  List<Dataset> _filteredDatasets = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Fetch datasets when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDatasets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDatasets(String query) {
    final datasets = Provider.of<DatasetProvider>(context, listen: false).datasets;
    setState(() {
      if (query.isEmpty && _selectedCategory == null) {
        _filteredDatasets = List.from(datasets);
      } else {
        _filteredDatasets = datasets.where((dataset) {
          bool matchesQuery = query.isEmpty || 
              dataset.title.toLowerCase().contains(query.toLowerCase()) ||
              dataset.description.toLowerCase().contains(query.toLowerCase()) ||
              dataset.type.toLowerCase().contains(query.toLowerCase());
          
          bool matchesCategory = _selectedCategory == null || 
              dataset.type.toLowerCase() == _selectedCategory!.toLowerCase();
          
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _filterDatasets(_searchController.text);
    });
  }

  Future<void> _refreshDatasets() async {
    try {
      await Provider.of<DatasetProvider>(context, listen: false).fetchDatasets();
      if (mounted) {
        setState(() {
          final datasets = Provider.of<DatasetProvider>(context, listen: false).datasets;
          _filteredDatasets = List.from(datasets); // Initialize with all datasets
          _filterDatasets(_searchController.text); // Apply any existing filters
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing datasets: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datasets Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const UploadDatasetScreen()),
          );
        },
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDatasets,
        child: Consumer<DatasetProvider>(
          builder: (context, datasetProvider, _) {
            if (datasetProvider.isLoading && datasetProvider.datasets.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (datasetProvider.error != null && datasetProvider.datasets.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading datasets',
                      style: TextStyle(fontSize: 18, color: Colors.red.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      datasetProvider.error!,
                      style: TextStyle(color: Colors.red.shade500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      onPressed: () {
                        datasetProvider.fetchDatasets();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }

            final datasets = datasetProvider.datasets;
            // Initialize filtered datasets if it's empty
            if (_filteredDatasets.isEmpty && datasets.isNotEmpty) {
              _filteredDatasets = List.from(datasets);
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and filter section
                  _buildSearchField(),
                  const SizedBox(height: 16),
                  
                  // Category filters
                  _buildCategoryFilters(datasets),
                  const SizedBox(height: 16),

                  // Stats cards
                  _buildStatsSection(datasets),
                  const SizedBox(height: 20),

                  // Datasets list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Datasets',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      if (datasetProvider.isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _filteredDatasets.isEmpty
                      ? const Expanded(
                          child: Center(
                            child: Text(
                              'No datasets found',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ),
                        )
                      : Expanded(
                          child: ListView.builder(
                            itemCount: _filteredDatasets.length,
                            itemBuilder: (context, index) {
                              return _buildDatasetCard(_filteredDatasets[index]);
                            },
                          ),
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(List<Dataset> datasets) {
    // Extract unique categories from datasets and filter to only supported types
    final supportedTypes = ['csv', 'excel', 'json', 'text'];
    final categories = datasets
        .map((dataset) => dataset.type.toLowerCase())
        .where((type) => supportedTypes.contains(type))
        .toSet()
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategory == null,
            onSelected: (selected) {
              if (selected) {
                _filterByCategory(null);
              }
            },
            backgroundColor: Colors.grey[200],
            selectedColor: primaryBlue.withOpacity(0.2),
            checkmarkColor: primaryBlue,
          ),
          const SizedBox(width: 8),
          ...categories.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: _selectedCategory == category,
              onSelected: (selected) {
                _filterByCategory(selected ? category : null);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: primaryBlue.withOpacity(0.2),
              checkmarkColor: primaryBlue,
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _filterDatasets,
      decoration: InputDecoration(
        hintText: 'Search datasets...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            _filterDatasets('');
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _buildStatsSection(List<Dataset> datasets) {
    // Calculate stats
    final totalDatasets = datasets.length;
    final Map<String, int> typeCount = {};
    
    for (var dataset in datasets) {
      typeCount[dataset.type] = (typeCount[dataset.type] ?? 0) + 1;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dataset Statistics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Datasets', 
                totalDatasets.toString(),
                Icons.dataset,
                primaryBlue,
              ),
              if (typeCount.isNotEmpty)
                _buildStatCard(
                  'Most Common Type', 
                  _getMostCommonType(typeCount),
                  Icons.category,
                  Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMostCommonType(Map<String, int> typeCount) {
    if (typeCount.isEmpty) return 'None';
    
    String mostCommonType = '';
    int highestCount = 0;
    
    typeCount.forEach((type, count) {
      if (count > highestCount) {
        highestCount = count;
        mostCommonType = type;
      }
    });
    
    return mostCommonType;
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.4,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatasetCard(Dataset dataset) {
    final downloadStatus = Provider.of<DatasetProvider>(context).downloadStatus[dataset.id];
    final isDownloading = downloadStatus?.status == DownloadState.inProgress;
    final isDownloaded = downloadStatus?.status == DownloadState.completed;
    final hasError = downloadStatus?.status == DownloadState.error;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          dataset.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dataset.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _pill(dataset.type),
                const SizedBox(width: 8),
                _pill(dataset.size),
                const SizedBox(width: 8),
                // Added timestamp if available
                if (dataset.createdAt != null)
                  _pill('Added ${_formatDate(dataset.createdAt!)}'),
              ],
            ),
          ],
        ),
        children: [
          const SizedBox(height: 8),
          _buildDetailRow('Type', dataset.type, Icons.category),
          _buildDetailRow('Size', dataset.size, Icons.data_usage),
          if (dataset.createdAt != null)
            _buildDetailRow('Added', _formatDate(dataset.createdAt!), Icons.calendar_today),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: const Text('Details'),
                onPressed: () {
                  _showDatasetDetails(context, dataset);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(color: primaryBlue),
                ),
              ),
              const SizedBox(width: 12),
              // Reactive download button that rebuilds on status change
              _buildDownloadButton(context, dataset),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context, Dataset dataset) {
    // Use a Consumer to listen to changes in DatasetProvider and rebuild only this button
    return Consumer<DatasetProvider>(
      builder: (context, provider, child) {
        final status = provider.downloadStatus[dataset.id];

        // Case 1: Download not started or status is null
        if (status == null || status.status == DownloadState.notStarted) {
          return ElevatedButton.icon(
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download'),
            onPressed: () {
              // Use the DownloadManager to start the download
              DownloadManager(context).downloadDataset(dataset);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          );
        }

        // Case 2: Switch based on the download status
        switch (status.status) {
          case DownloadState.inProgress:
            return ElevatedButton(
              onPressed: null, // Disable button while downloading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade400,
                disabledForegroundColor: Colors.white.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      value: status.progress > 0 ? status.progress : null, // Indeterminate if 0
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(status.progress * 100).toInt()}%'),
                ],
              ),
            );
          case DownloadState.completed:
            return ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Downloaded'),
              onPressed: () {
                // Optional: Implement logic to open the file or show its location
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('File saved at: ${status.filePath}')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          case DownloadState.error:
            return ElevatedButton.icon(
              icon: const Icon(Icons.error, size: 18),
              label: const Text('Retry'),
              onPressed: () {
                // Retry the download
                DownloadManager(context).downloadDataset(dataset);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            );
          default:
            return Container(); // Should not be reached
        }
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showDatasetDetails(BuildContext context, Dataset dataset) {
    final downloadStatus = Provider.of<DatasetProvider>(context, listen: false).downloadStatus[dataset.id];
    final isDownloading = downloadStatus?.status == DownloadState.inProgress;
    final isDownloaded = downloadStatus?.status == DownloadState.completed;
    final hasError = downloadStatus?.status == DownloadState.error;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
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
                  _buildDetailCard('Type', dataset.type, Icons.category),
                  _buildDetailCard('Size', dataset.size, Icons.data_usage),
                  if (dataset.createdAt != null)
                    _buildDetailCard('Added', _formatDate(dataset.createdAt!), Icons.calendar_today),
                  _buildDetailCard('ID', dataset.id, Icons.fingerprint),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    // Using DownloadManager with some style customization
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: DownloadManager(context).buildDownloadButton(dataset),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            Icon(icon, color: primaryBlue, size: 24),
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

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
