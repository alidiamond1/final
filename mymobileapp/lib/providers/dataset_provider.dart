import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import '../services/dataset_service.dart';

class DatasetProvider extends ChangeNotifier {
  List<Dataset> datasets = [];
  bool isLoading = false;
  String? error;
  Dataset? selectedDataset;

  // Download status tracking
  Map<String, DownloadStatus> downloadStatus = {};

  // Port for receiving download progress updates
  final ReceivePort _port = ReceivePort();

  DatasetProvider() {
    _bindBackgroundIsolate();
  }

  @override
  void dispose() {
    _unbindBackgroundIsolate();
    super.dispose();
  }

  void _bindBackgroundIsolate() {
    final isSuccess = IsolateNameServer.registerPortWithName(
      _port.sendPort,
      'downloader_send_port',
    );
    if (!isSuccess) {
      _unbindBackgroundIsolate();
      _bindBackgroundIsolate();
      return;
    }
    _port.listen((dynamic data) {
      final taskId = data[0] as String;
      final status = DownloadTaskStatus.fromInt(data[1] as int);
      final progress = data[2] as int;

      String? datasetId;
      for (final entry in downloadStatus.entries) {
        if (entry.value.taskId == taskId) {
          datasetId = entry.key;
          break;
        }
      }

      if (datasetId != null) {
        if (status == DownloadTaskStatus.running) {
          updateDownloadStatus(datasetId, DownloadState.inProgress, progress / 100.0,
              taskId: taskId);
        } else if (status == DownloadTaskStatus.complete) {
          updateDownloadStatus(datasetId, DownloadState.completed, 1.0, taskId: taskId);
        } else if (status == DownloadTaskStatus.failed ||
            status == DownloadTaskStatus.canceled) {
          updateDownloadStatus(datasetId, DownloadState.error, 0.0,
              error: 'Download failed', taskId: taskId);
        }
      }
    });
  }

  void _unbindBackgroundIsolate() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> fetchDatasets() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fetchedDatasets = await DatasetService.getDatasets();
      datasets = fetchedDatasets;
      error = null;
    } catch (e) {
      error = e.toString();
      datasets = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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

  Future<String?> downloadDataset(Dataset dataset) async {
    final existingStatus = downloadStatus[dataset.id];
    if (existingStatus?.status == DownloadState.completed &&
        existingStatus?.filePath != null) {
      debugPrint('File already downloaded: ${existingStatus?.filePath}');
      return existingStatus?.filePath;
    }

    updateDownloadStatus(dataset.id, DownloadState.inProgress, 0);

    try {
      final permissionStatus = await Permission.storage.request();
      if (!permissionStatus.isGranted) {
        throw Exception('Storage permission not granted');
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        throw Exception('Could not get external storage directory');
      }

      final savedDir = externalDir.path;

      final fileExtension = _getFileExtension(dataset.type);
      final fileName =
          '${dataset.title.replaceAll(' ', '_').toLowerCase()}$fileExtension';
      final downloadUrl =
          '${DatasetService.baseUrl}/datasets/download/${dataset.id}';

      final taskId = await FlutterDownloader.enqueue(
        url: downloadUrl,
        savedDir: savedDir,
        fileName: fileName,
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
      );

      if (taskId != null) {
        final filePath = '$savedDir/$fileName';
        updateDownloadStatus(dataset.id, DownloadState.inProgress, 0,
            taskId: taskId, filePath: filePath);
        debugPrint(
            'Download started with task ID: $taskId for URL: $downloadUrl');
        return taskId;
      } else {
        throw Exception('Failed to start download task');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      updateDownloadStatus(dataset.id, DownloadState.error, 0,
          error: e.toString());
      return null;
    }
  }

  void updateDownloadStatus(String datasetId, DownloadState status, double progress,
      {String? filePath, String? error, String? taskId}) {
    final currentStatus = downloadStatus[datasetId];
    downloadStatus[datasetId] = DownloadStatus(
      status: status,
      progress: progress,
      filePath: filePath ?? currentStatus?.filePath,
      error: error,
      taskId: taskId ?? currentStatus?.taskId,
    );
    notifyListeners();
  }

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
