import 'package:flutter/material.dart';
import '../services/dataset_service.dart';

class DatasetProvider extends ChangeNotifier {
  List<Dataset> datasets = [];
  bool isLoading = false;
  String? error;
  Dataset? selectedDataset;
  
  // Download status tracking
  Map<String, DownloadStatus> downloadStatus = {};

  // Fetch datasets method with error handling
  Future<void> fetchDatasets() async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      // Fetch data from the backend
      final fetchedDatasets = await DatasetService.getDatasets();
      datasets = fetchedDatasets;
      error = null;
    } catch (e) {
      // Handle any errors
      error = e.toString();
      datasets = []; // Clear datasets on error instead of using mock data
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Get dataset by ID
  Future<void> getDatasetById(String id) async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      selectedDataset = await DatasetService.getDataset(id);
      error = null;
    } catch (e) {
      error = e.toString();
      selectedDataset = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  // Download a dataset
  Future<String?> downloadDataset(Dataset dataset) async {
    // Check if file is already downloaded
    final existingStatus = downloadStatus[dataset.id];
    if (existingStatus?.status == DownloadState.completed && existingStatus?.filePath != null) {
      debugPrint('File already downloaded: ${existingStatus!.filePath}');
      // File already downloaded, just return the path
      return existingStatus.filePath;
    }
    
    // Update download status to in progress
    downloadStatus[dataset.id] = DownloadStatus(
      status: DownloadState.inProgress,
      progress: 0,
    );
    notifyListeners();
    
    try {
      debugPrint('Starting download for dataset: ${dataset.id}');
      
      // Create a filename based on dataset title and type
      final fileExtension = _getFileExtension(dataset.type);
      final fileName = '${dataset.title.replaceAll(' ', '_').toLowerCase()}$fileExtension';
      
      // Download the file
      final filePath = await DatasetService.downloadDataset(dataset.id, fileName);
      debugPrint('Download completed: $filePath');
      
      // Update download status to completed
      downloadStatus[dataset.id] = DownloadStatus(
        status: DownloadState.completed,
        progress: 1.0,
        filePath: filePath,
      );
      notifyListeners();
      
      return filePath;
    } catch (e) {
      debugPrint('Download error: $e');
      // Update download status to error
      downloadStatus[dataset.id] = DownloadStatus(
        status: DownloadState.error,
        error: e.toString(),
      );
      notifyListeners();
      return null;
    }
  }
  
  // Method to update download status from anywhere
  void updateDownloadStatus(String datasetId, DownloadState status, double progress, {String? filePath, String? error, String? taskId}) {
    downloadStatus[datasetId] = DownloadStatus(
      status: status,
      progress: progress,
      filePath: filePath,
      error: error,
      taskId: taskId,
    );
    notifyListeners();
  }

  // Helper method to get file extension based on dataset type
  String _getFileExtension(String type) {
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
}

// Track download state
enum DownloadState {
  notStarted,
  inProgress,
  completed,
  error,
}

class DownloadStatus {
  final DownloadState status;
  final double progress;
  final String? filePath;
  final String? error;
  final String? taskId;
  
  DownloadStatus({
    required this.status,
    this.progress = 0,
    this.filePath,
    this.error,
    this.taskId,
  });
}
