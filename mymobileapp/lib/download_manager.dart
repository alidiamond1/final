import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/dataset_service.dart';
import 'providers/dataset_provider.dart';

/// Extension methods for downloading datasets
extension DatasetDownloadExtension on Dataset {
  /// Get the appropriate file extension based on dataset type
  String get fileExtension {
    switch (type.toLowerCase()) {
      case 'text':
        return '.txt';
      case 'csv':
        return '.csv';
      case 'json':
        return '.json';
      case 'excel':
        return '.xlsx';
      case 'audio':
        return '.zip';
      case 'dictionary':
        return '.json';
      default:
        return '.zip';
    }
  }
  
  /// Generate a filename for downloading
  String get downloadFilename {
    return '${title.replaceAll(' ', '_').toLowerCase()}$fileExtension';
  }
  
  /// Check if the dataset is currently downloading in the given context
  bool isDownloading(BuildContext context) {
    final downloadStatus = Provider.of<DatasetProvider>(context).downloadStatus[id];
    return downloadStatus?.status == DownloadState.inProgress;
  }
  
  /// Check if the dataset has been downloaded in the given context
  bool isDownloaded(BuildContext context) {
    final downloadStatus = Provider.of<DatasetProvider>(context).downloadStatus[id];
    return downloadStatus?.status == DownloadState.completed;
  }
  
  /// Check if there was an error downloading the dataset in the given context
  bool hasDownloadError(BuildContext context) {
    final downloadStatus = Provider.of<DatasetProvider>(context).downloadStatus[id];
    return downloadStatus?.status == DownloadState.error;
  }
  
  /// Download the dataset in the given context
  Future<String?> download(BuildContext context) async {
    final provider = Provider.of<DatasetProvider>(context, listen: false);
    return provider.downloadDataset(this);
  }
}

/// Helper class for handling dataset downloads
class DownloadManager {
  final BuildContext context;
  
  DownloadManager(this.context);
  
  /// Download a dataset
  Future<String?> downloadDataset(Dataset dataset) async {
    try {
      final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);
      
      // Show in-progress snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading dataset...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
      
      final filePath = await datasetProvider.downloadDataset(dataset);
      
      if (filePath != null) {
        // Only show success message if context is still mounted
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${dataset.title} downloaded to Downloads folder'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
      
      return filePath;
    } catch (e) {
      // Only show error message if context is still mounted
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }
  
  /// Build a download button with appropriate state
  Widget buildDownloadButton(Dataset dataset) {
    return Consumer<DatasetProvider>(
      builder: (context, provider, _) {
        final downloadStatus = provider.downloadStatus[dataset.id];
        final isDownloading = downloadStatus?.status == DownloadState.inProgress;
        final isDownloaded = downloadStatus?.status == DownloadState.completed;
        final hasError = downloadStatus?.status == DownloadState.error;
        
        const Color primaryBlue = Color(0xFF144BA6);
        
        if (isDownloading) {
          // Show download progress
          return ElevatedButton.icon(
            icon: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            label: const Text('Downloading...'),
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue.withOpacity(0.7),
              foregroundColor: Colors.white,
            ),
          );
        } else if (isDownloaded) {
          // Show download completed
          return ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Downloaded'),
            onPressed: null, // No action on press since we don't want to open the file
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          );
        } else if (hasError) {
          // Show download error with retry option
          return ElevatedButton.icon(
            icon: const Icon(Icons.error_outline),
            label: const Text('Try Again'),
            onPressed: () => downloadDataset(dataset),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          );
        } else {
          // Default download button
          return ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: () => downloadDataset(dataset),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
          );
        }
      },
    );
  }
} 