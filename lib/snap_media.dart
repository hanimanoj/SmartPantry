import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'topBar.dart';

class SnapItemPhotoScreen extends StatefulWidget {
  const SnapItemPhotoScreen({super.key});

  @override
  State<SnapItemPhotoScreen> createState() => _SnapItemPhotoScreenState();
}

class _SnapItemPhotoScreenState extends State<SnapItemPhotoScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();
  
  XFile? _capturedFile;      
  bool _isUploading = false; 

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0], 
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print("Camera initialization failed: $e");
    }
  }

  Future<void> _confirmAndUpload() async {
  if (_capturedFile == null) return;

  setState(() {
    _isUploading = true;
  });

  try {
    String base64Image;

    if (kIsWeb) {
      final bytes = await _capturedFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    } else {
      final bytes = await File(_capturedFile!.path).readAsBytes();
      base64Image = base64Encode(bytes);
    }

    Navigator.pop(context, base64Image);

  } catch (e) {
    print(e);
  }

  setState(() {
    _isUploading = false;
  });
}

  Future<void> _takePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final XFile photo = await _cameraController!.takePicture();

      await _cameraController?.dispose();

      setState(() {
        _isCameraInitialized = false;
        _capturedFile = photo;
      });
    } catch (e) {
      print("Error capturing photo: $e");
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (_cameraController != null) {
        await _cameraController?.dispose();
      }

      setState(() {
        _isCameraInitialized = false;
        _capturedFile = pickedFile;
      });
    }
  }

  void _retakePhoto() async {
    setState(() {
      _capturedFile = null;
    });

    await _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFDCEDC8),
    appBar: const PantryTopBar(),

    body: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              // Left back action button
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2C5E3B)),
                onPressed: () => Navigator.pop(context),
              ),
              
              // Centered context-dependent title string
              Expanded(
                child: Center(
                  child: Text(
                    _capturedFile != null ? 'Preview Photo' : 'Snap Item Photo',
                    style: const TextStyle(
                      color: Color(0xFF2C5E3B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              
              // Right side action panel area placeholder
              SizedBox(
                width: 48, // Keeps title balanced in center bounds
                child: _capturedFile != null && !_isUploading
                    ? IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF2C5E3B)),
                        onPressed: _retakePhoto,
                        tooltip: 'Retake Photo',
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        //The core media preview stack workspace container logic 
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                bottom: 140,
                child: _capturedFile != null
                    ? (kIsWeb 
                        ? Image.network(_capturedFile!.path, fit: BoxFit.cover) 
                        : Image.file(File(_capturedFile!.path), fit: BoxFit.cover)
                      ) 
                      : (_isCameraInitialized &&
                        _cameraController != null
                      ? CameraPreview(_cameraController!)
                      : const Center(
                          child: CircularProgressIndicator(
                          color: Colors.green,
                          ),
                        )
                      )
              ),

              // Bottom Control Panel Sheet
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _capturedFile != null
                          ? SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: _isUploading ? null : _confirmAndUpload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2C5E3B), 
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                                label: const Text(
                                  'Confirm Selection',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -35),
                                  child: GestureDetector(
                                    onTap: _takePhoto,
                                    child: Container(
                                      height: 75,
                                      width: 75,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_outlined,
                                        size: 32,
                                        color: Color(0xFF2E3D30),
                                      ),
                                    ),
                                  ),
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -15),
                                  child: SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.65,
                                    height: 48,
                                    child: TextButton.icon(
                                      onPressed: _pickFromGallery,
                                      style: TextButton.styleFrom(
                                        backgroundColor: const Color(0xFFCDDEC3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      icon: const Icon(Icons.image_outlined, color: Color(0xFF2C5E3B)),
                                      label: const Text(
                                        'Choose from Gallery',
                                        style: TextStyle(
                                          color: Color(0xFF2C5E3B),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),

              if (_isUploading)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Uploading to Smart Pantry Storage...',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        )
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
}