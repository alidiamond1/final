import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/dataset_service.dart';
import 'providers/dataset_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart'; // Add import for Dio package for faster downloads
import 'services/auth_service.dart'; // Add import for AuthService

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
  final Dio _dio = Dio(); // Dio instance for faster downloads
  
  DownloadManager(this.context);
  
  /// Download a dataset with improved speed using Dio
  Future<String?> downloadDataset(Dataset dataset) async {
    try {
      final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);
      
      // Show in-progress snackbar
      if (context.mounted) {
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
      }
      
      // Use the optimized download method for better speed
      final filePath = await _optimizedDownload(dataset);
      
      if (filePath != null) {
        // Update provider with completed status
        datasetProvider.downloadStatus[dataset.id] = DownloadStatus(
          status: DownloadState.completed,
          progress: 1.0,
          filePath: filePath,
        );
        datasetProvider.notifyListeners();
        
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
      // Update provider with error status
      final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);
      datasetProvider.downloadStatus[dataset.id] = DownloadStatus(
        status: DownloadState.error,
        error: e.toString(),
      );
      datasetProvider.notifyListeners();
      
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
  
  /// Optimized download method using Dio for faster downloads
  Future<String?> _optimizedDownload(Dataset dataset) async {
    final token = await AuthService.getToken();
    
    try {
      // Get download directory
      final downloadDir = await _getDownloadDir();
      
      // Create full file path
      final fileName = dataset.downloadFilename;
      final filePath = '${downloadDir.path}/$fileName';
      
      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('File already exists: $filePath');
        return filePath;
      }
      
      // Get download URL - ensure it matches the backend route
      final downloadUrl = '${DatasetService.baseUrl}/${dataset.id}/download';
      debugPrint('Downloading from: $downloadUrl');
      
      // Set up options with headers and receive progress updates
      final options = Options(
        headers: token != null ? {
          'Authorization': 'Bearer $token',
          'Accept': '*/*',  // Accept any content type
        } : {
          'Accept': '*/*',  // Accept any content type
        },
        responseType: ResponseType.bytes,
        followRedirects: true,
        receiveTimeout: const Duration(minutes: 5), // Increase timeout for large files
      );
      
      // Use Dio for faster download with progress updates
      final response = await _dio.get(
        downloadUrl,
        options: options,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            // Update download progress in provider
            final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);
            datasetProvider.downloadStatus[dataset.id] = DownloadStatus(
              status: DownloadState.inProgress,
              progress: progress,
            );
            datasetProvider.notifyListeners();
            debugPrint('Download progress: ${(progress * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      // Check if response is valid
      if (response.statusCode == 200 && response.data != null) {
        // Write file to storage
        await file.writeAsBytes(response.data);
        debugPrint('File downloaded to: $filePath');
        return filePath;
      } else {
        debugPrint('Download failed with status: ${response.statusCode}');
        throw Exception('Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Optimized download error: $e');
      throw Exception('Download error: ${e.toString()}');
    }
  }
  
  /// Helper method to get download directory
  Future<Directory> _getDownloadDir() async {
    try {
      if (Platform.isAndroid) {
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Create a custom folder in external storage
            final downloadDir = Directory('${directory.path}/SomaliDatasets');
            
            // Create directory if it doesn't exist
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            return downloadDir;
          } else {
            throw Exception('External storage directory is null');
          }
        } catch (e) {
          // Fall back to application documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final downloadsDir = Directory('${appDir.path}/downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir;
        }
      } else if (Platform.isIOS) {
        // On iOS, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
    } catch (e) {
      debugPrint('Error getting download directory: $e');
      // Fallback to application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDocDir.path}/downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir;
    }
  }
  
  /// Build a download button with appropriate state and progress indicator
  Widget buildDownloadButton(Dataset dataset) {
    return Consumer<DatasetProvider>(
      builder: (context, provider, _) {
        final downloadStatus = provider.downloadStatus[dataset.id];
        final isDownloading = downloadStatus?.status == DownloadState.inProgress;
        final isDownloaded = downloadStatus?.status == DownloadState.completed;
        final hasError = downloadStatus?.status == DownloadState.error;
        final progress = downloadStatus?.progress ?? 0.0;
        
        const Color primaryBlue = Color(0xFF144BA6);
        
        if (isDownloading) {
          // Show download progress with percentage
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                label: Text('${(progress * 100).toStringAsFixed(0)}%'),
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue.withOpacity(0.7),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
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