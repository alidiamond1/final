import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class Dataset {
  final String id;
  final String title;
  final String description;
  final String type;
  final String size;
  final DateTime? createdAt;
  
  Dataset({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.size,
    this.createdAt,
  });
  
  factory Dataset.fromJson(Map<String, dynamic> json) {
    return Dataset(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? 'Untitled Dataset',
      description: json['description'] ?? 'No description',
      type: json['type'] ?? 'unknown',
      size: json['size'] ?? 'unknown',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class DatasetService {
  // Backend API URL - Change this to match your server's address
  static const String baseUrl = 'http://10.0.2.2:3000/api/datasets';
  
  // Get all datasets
  static Future<List<Dataset>> getDatasets() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        // Log response for debugging
        debugPrint('Response body: ${response.body}');
        
        final data = jsonDecode(response.body);
        if (data['datasets'] != null) {
          final List<dynamic> datasetsJson = data['datasets'];
          return datasetsJson.map((json) => Dataset.fromJson(json)).toList();
        } else {
          throw Exception('Invalid response format: datasets field missing');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication errors
        await AuthService.logout(); // Clear invalid token
        throw Exception('Authentication expired. Please log in again.');
      } else {
        // Handle other errors
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to load datasets (Status: ${response.statusCode})');
        } catch (e) {
          throw Exception('Failed to load datasets (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Error fetching datasets: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Get a single dataset by ID
  static Future<Dataset> getDataset(String id) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['dataset'] != null) {
          return Dataset.fromJson(data['dataset']);
        } else {
          throw Exception('Invalid response format: dataset field missing');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Dataset not found');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to load dataset');
        } catch (e) {
          throw Exception('Failed to load dataset (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Error fetching dataset: $e');
      throw Exception('Network error: ${e.toString()}');
    }
  }
  
  // Download a dataset file to an accessible location
  static Future<String> downloadDataset(String id, String fileName) async {
    final token = await AuthService.getToken();
    
    try {
      // Get download directory path based on platform
      final downloadDir = await _getDownloadDir();
      debugPrint('Download directory: ${downloadDir.path}');
      
      // Create full file path
      final filePath = '${downloadDir.path}/$fileName';
      
      // Check if file already exists
      final file = File(filePath);
      if (await file.exists()) {
        debugPrint('File already exists: $filePath');
        return filePath;
      }
      
      // Get download URL
      final downloadUrl = '$baseUrl/$id/download';
      debugPrint('Downloading from: $downloadUrl');
      
      // Using http client to download the file
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: token != null ? {
          'Authorization': 'Bearer $token',
        } : {},
      );
      
      if (response.statusCode == 200) {
        try {
          // Try to write file directly
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('File downloaded to: $filePath');
          return filePath;
        } catch (e) {
          debugPrint('Error writing file directly: $e');
          
          // Try alternative approach - write to app documents first
          final appDir = await getApplicationDocumentsDirectory();
          final tempFilePath = '${appDir.path}/$fileName';
          final tempFile = File(tempFilePath);
          
          await tempFile.writeAsBytes(response.bodyBytes);
          debugPrint('File downloaded to app documents: $tempFilePath');
          return tempFilePath;
        }
      } else {
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to download dataset');
        } catch (e) {
          throw Exception('Failed to download dataset: ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('Download error: $e');
      throw Exception('Download error: ${e.toString()}');
    }
  }
  
  // Get the download directory
  static Future<Directory> _getDownloadDir() async {
    try {
      if (Platform.isAndroid) {
        try {
          // Instead of external_path, use path_provider
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
          debugPrint('Error getting external storage path: $e');
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

  // Upload a dataset
  static Future<Dataset> uploadDataset(Map<String, dynamic> datasetData) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw Exception('Not authenticated. Please log in again.');
    }
    
    try {
      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add text fields
      request.fields['title'] = datasetData['title'];
      request.fields['description'] = datasetData['description'];
      request.fields['type'] = datasetData['type'];
      request.fields['size'] = datasetData['size'];
      
      // Add file if present
      if (datasetData['file'] != null) {
        final file = datasetData['file'] as File;
        final fileName = file.path.split('/').last;
        final fileStream = http.ByteStream(file.openRead());
        final fileLength = await file.length();
        
        final multipartFile = http.MultipartFile(
          'file',
          fileStream,
          fileLength,
          filename: fileName,
        );
        
        request.files.add(multipartFile);
      }
      
      debugPrint('Sending upload request to $baseUrl');
      
      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('Upload successful: ${response.body}');
        return Dataset.fromJson(data['dataset']);
      } else {
        debugPrint('Upload failed: ${response.statusCode}, ${response.body}');
        // Try to parse error response
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['error'] ?? 'Failed to upload dataset (Status: ${response.statusCode})');
        } catch (e) {
          throw Exception('Failed to upload dataset (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Error uploading dataset: $e');
      throw Exception('Upload error: ${e.toString()}');
    }
  }
}