import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'db_helper.dart';
import 'sync_manager.dart';
import 'my_grievances.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final DBHelper _dbHelper = DBHelper();

  XFile? _capturedImage;
  bool _isLoading = false;
  String _selectedLanguage = 'en';

  // Multilingual dictionary supporting English, Hindi, and Marathi
  final Map<String, Map<String, String>> _localizedStrings = {
    'en': {
      'title': 'JJM Grievance Portal',
      'desc_hint': 'Describe the water issue (low pressure, leak)...',
      'capture_photo': 'Take Issue Photo',
      'photo_captured': 'Photo Attached',
      'submit_btn': 'Submit Grievance',
      'submitting': 'Locating & Storing...',
      'success_msg': 'Saved! Will sync when online.',
      'error_photo': 'Please capture a photo first.',
      'error_location': 'Location services required.',
    },
    'hi': {
      'title': 'जल जीवन मिशन पोर्टल',
      'desc_hint': 'पानी की समस्या का विवरण दें (कम दबाव, रिसाव)...',
      'capture_photo': 'समस्या का फोटो लें',
      'photo_captured': 'फोटो संलग्न',
      'submit_btn': 'शिकायत दर्ज करें',
      'submitting': 'सहेजा जा रहा है...',
      'success_msg': 'सुरक्षित हो गई! ऑनलाइन होने पर सिंक होगी।',
      'error_photo': 'कृपया पहले फोटो लें।',
      'error_location': 'लोकेशन सेवाएं आवश्यक हैं।',
    },
    'mr': {
      'title': 'जेजेएम तक्रार निवारण पोर्टल',
      'desc_hint': 'पाण्याच्या समस्येचे वर्णन करा (कमी दाब, गळती)...',
      'capture_photo': 'समस्येचा फोटो काढा',
      'photo_captured': 'फोटो जोडला गेला',
      'submit_btn': 'तक्रार नोंदवा',
      'submitting': 'जतन करत आहे...',
      'success_msg': 'जतन केले! ऑनलाइन झाल्यावर सिंक होईल.',
      'error_photo': 'कृपया आधी फोटो काढा.',
      'error_location': 'स्थान (Location) सेवा आवश्यक आहे.',
    },
  };

  String _t(String key) => _localizedStrings[_selectedLanguage]?[key] ?? key;

  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo != null) {
      setState(() => _capturedImage = photo);
    }
  }

  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<void> _submitGrievance() async {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('error_photo'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final Position? position = await _determinePosition();
    if (position == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_t('error_location'))),
        );
      }
      return;
    }

    final newGrievance = {
      'user_id': 'CITIZEN_01',
      'description': _descController.text.trim().isEmpty
          ? 'No description'
          : _descController.text.trim(),
      'image_path': _capturedImage!.path,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'sync_status': 0,
    };

    await _dbHelper.insertGrievance(newGrievance);
    SyncManager().syncPendingGrievances();

    setState(() {
      _isLoading = false;
      _capturedImage = null;
      _descController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.teal[700],
          content: Text(_t('success_msg')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_t('title'), style: const TextStyle(fontSize: 18)),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyGrievancesScreen(),
                ),
              );
            },
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            dropdownColor: Colors.teal[700],
            underline: const SizedBox(),
            icon: const Icon(Icons.language, color: Colors.white),
            items: const [
              DropdownMenuItem(
                value: 'en',
                child: Text('English', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'hi',
                child: Text('हिंदी', style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: 'mr',
                child: Text('मराठी', style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedLanguage = val);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _t('desc_hint'),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.teal[800]!, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_t('capture_photo')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.teal[50],
                foregroundColor: Colors.teal[900],
              ),
            ),
            if (_capturedImage != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_capturedImage!.path),
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _t('photo_captured'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitGrievance,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      _t('submit_btn'),
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}