import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'providers/auth_provider.dart';
import 'providers/dataset_provider.dart';
import 'services/dataset_service.dart';

class UploadDatasetScreen extends StatefulWidget {
  const UploadDatasetScreen({super.key});

  @override
  State<UploadDatasetScreen> createState() => _UploadDatasetScreenState();
}

class _UploadDatasetScreenState extends State<UploadDatasetScreen> {
  static const Color primaryBlue = Color(0xFF144BA6);
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  File? _selectedFile;
  String? _selectedFileName;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _sizeController.dispose();
    super.dispose();
  }
  
  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _typeController.clear();
      _sizeController.clear();
      _errorMessage = null;
      _isSuccess = false;
      _selectedFile = null;
      _selectedFileName = null;
    });
  }

  Future<void> _pickFile() async {
    try {
      // Use file picker with allowed extensions - no need to request permission
      // SAF (Storage Access Framework) handles permissions automatically
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv', 'json', 'xlsx', 'xls'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        
        // Make sure we have a valid path
        if (platformFile.path == null) {
          setState(() {
            _errorMessage = 'Could not get file path';
          });
          return;
        }
        
        final file = File(platformFile.path!);
        final fileSize = file.lengthSync();
        String formattedSize;
        
        // Format the size in appropriate units (KB, MB, GB)
        if (fileSize < 1024) {
          formattedSize = '$fileSize B';
        } else if (fileSize < 1024 * 1024) {
          formattedSize = '${(fileSize / 1024).toStringAsFixed(2)} KB';
        } else if (fileSize < 1024 * 1024 * 1024) {
          formattedSize = '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB';
        } else {
          formattedSize = '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
        }
        
        setState(() {
          _selectedFile = file;
          _selectedFileName = platformFile.name;
          _sizeController.text = formattedSize;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting file: ${e.toString()}';
      });
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a file to upload';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });
    
    try {
      // Show uploading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading dataset to database...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Create a dataset object
      final datasetToUpload = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'type': _typeController.text,
        'size': _sizeController.text,
        'file': _selectedFile!
      };
      
      // Upload the dataset to database
      final uploadedDataset = await DatasetService.uploadDataset(datasetToUpload);
      
      // Refresh datasets list after successful upload
      if (mounted) {
        await Provider.of<DatasetProvider>(context, listen: false).fetchDatasets();
      }
      
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dataset "${uploadedDataset.title}" successfully saved to database!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
      // Reset the form after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _resetForm();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Upload failed: ${e.toString()}';
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Dataset'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Upload a New Dataset',
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Fill out the form below to upload a new dataset to the repository.',
                            style: TextStyle(
                              fontSize: 14, 
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                
                // Form fields with improved styling
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dataset Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Dataset Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Dataset Title',
                            hintText: 'Enter a descriptive title',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBlue, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.title, color: primaryBlue),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) => 
                            value!.isEmpty ? 'Please enter a title' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            hintText: 'Describe the dataset and its contents',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: primaryBlue, width: 2),
                            ),
                            prefixIcon: const Icon(Icons.description, color: primaryBlue),
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (value) => 
                            value!.isEmpty ? 'Please enter a description' : null,
                        ),
                        const SizedBox(height: 20),
                        
                        // Type and Size fields in a row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Type',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                      color: Colors.grey.shade50,
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _typeController.text.isEmpty ? null : _typeController.text,
                                      decoration: InputDecoration(
                                        hintText: 'Select type',
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        prefixIcon: const Icon(Icons.category, color: primaryBlue),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'csv', child: Text('CSV')),
                                        DropdownMenuItem(value: 'excel', child: Text('Excel')),
                                        DropdownMenuItem(value: 'json', child: Text('JSON')),
                                        DropdownMenuItem(value: 'text', child: Text('Text')),
                                      ],
                                      validator: (value) => 
                                        value == null || value.isEmpty ? 'Please select a type' : null,
                                      onChanged: (value) {
                                        setState(() {
                                          _typeController.text = value ?? '';
                                        });
                                      },
                                      icon: const Icon(Icons.arrow_drop_down, color: primaryBlue),
                                      dropdownColor: Colors.white,
                                      isExpanded: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Size',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _sizeController,
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'File size (auto)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: primaryBlue, width: 2),
                                      ),
                                      prefixIcon: const Icon(Icons.data_usage, color: primaryBlue),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // File picker
                Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade50,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _selectedFile != null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.insert_drive_file, size: 48, color: Colors.green),
                              const SizedBox(height: 12),
                              Text(
                                _selectedFileName ?? 'File selected',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.refresh),
                                label: const Text('Change File'),
                                onPressed: _pickFile,
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.upload_file, size: 48, color: Colors.grey.shade600),
                              const SizedBox(height: 12),
                              const Text(
                                'Select a file to upload',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.file_open),
                                label: const Text('Browse Files'),
                                onPressed: _pickFile,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: primaryBlue,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: primaryBlue),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),
                        const Text(
                          'Supported formats: .txt, .csv, .json, .xlsx, .xls',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Error message with improved styling
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Success message with improved styling
                if (_isSuccess)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Dataset uploaded successfully!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                // Submit button with improved styling
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Uploading...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const Text(
                            'Upload Dataset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
