import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/dataset_service.dart';
import 'providers/dataset_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/auth_service.dart';

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
  
  DownloadManager(this.context);


  
  /// Download a dataset using flutter_downloader
  Future<void> downloadDataset(Dataset dataset) async {
    try {
      final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);

      // 1. Request notification permission for download progress.
      // On modern Android, storage permission is not required for flutter_downloader
      // to save files to the public Downloads directory.
      await Permission.notification.request();

      // 2. Get download directory
      final dir = await _getDownloadDir();
      final fileName = dataset.downloadFilename;
      final filePath = '${dir.path}/$fileName';

      // 3. Check if file already exists
      if (await File(filePath).exists()) {
        debugPrint('File already exists: $filePath');
        datasetProvider.updateDownloadStatus(dataset.id, DownloadState.completed, 1.0, filePath: filePath);
        _showSuccessMessage(dataset, filePath);
        return;
      }

      // 4. Get authentication token
      final token = await AuthService.getToken();
      if (token == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log-in to download datasets'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // 5. Enqueue the download
      final taskId = await FlutterDownloader.enqueue(
        url: '${DatasetService.baseUrl}/${dataset.id}/download',
        savedDir: dir.path,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        allowCellular: true,
        headers: {'Authorization': 'Bearer $token', 'Accept': '*/*'},
      );

      if (taskId != null) {
        debugPrint('⬇️ Download enqueued with taskId: $taskId');
        datasetProvider.updateDownloadStatus(dataset.id, DownloadState.inProgress, 0.0, taskId: taskId, filePath: filePath);
      } else {
        throw Exception('Failed to enqueue download task.');
      }

    } catch (e) {
      debugPrint('❌ Download error: $e');
      final datasetProvider = Provider.of<DatasetProvider>(context, listen: false);
      datasetProvider.updateDownloadStatus(dataset.id, DownloadState.error, 0.0, error: e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: Failed to download ${dataset.title}'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  /// Show success message after download completes
  void _showSuccessMessage(Dataset dataset, String filePath) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${dataset.title} downloaded successfully'),
              Text(
                'File saved in Downloads/SomaliDatasets',
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
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
  
  /// Helper method to get download directory
  Future<Directory> _getDownloadDir() async {
    try {
      if (Platform.isAndroid) {
        try {
          // First attempt: Get Android Downloads directory (API level >= 29)
          final directory = await getExternalStorageDirectory();
          debugPrint('📁 External storage path: ${directory?.path}');
          
          if (directory != null) {
            // Create a custom folder that will be visible to the user
            // in the Android/data/[package_name]/files/SomaliDatasets folder
            final downloadDir = Directory('${directory.path}/SomaliDatasets');
            
            // Create directory if it doesn't exist
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            
            debugPrint('📁 Created download directory at: ${downloadDir.path}');
            return downloadDir;
          } else {
            throw Exception('External storage directory is null');
          }
        } catch (e) {
          debugPrint('❌ Error getting external storage: $e');
          
          // Second attempt: Use application documents directory
          final appDir = await getApplicationDocumentsDirectory();
          debugPrint('📁 App documents directory: ${appDir.path}');
          
          final downloadsDir = Directory('${appDir.path}/SomaliDatasets');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          debugPrint('📁 Created fallback download directory at: ${downloadsDir.path}');
          return downloadsDir;
        }
      } else if (Platform.isIOS) {
        // On iOS, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/SomaliDatasets');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        debugPrint('📁 Created iOS download directory at: ${downloadsDir.path}');
        return downloadsDir;
      } else {
        // For other platforms
        final directory = await getApplicationDocumentsDirectory();
        final downloadsDir = Directory('${directory.path}/SomaliDatasets');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        debugPrint('📁 Created download directory at: ${downloadsDir.path}');
        return downloadsDir;
      }
    } catch (e) {
      debugPrint('❌ Error getting download directory: $e');
      // Last resort fallback
      final appDocDir = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${appDocDir.path}/SomaliDatasets');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      debugPrint('📁 Created last-resort download directory at: ${downloadsDir.path}');
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