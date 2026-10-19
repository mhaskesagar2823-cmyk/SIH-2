import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  bool _isSyncing = false;
  
  // Stores the IP and port so main_screen.dart doesn't have to provide them every time
String _serverIp = '192.168.137.1';
  int _port = 8000;

  void initializeSyncListener(String serverIp, int port) {
    _serverIp = serverIp;
    _port = port;
    
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      bool hasInternet = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet
      );

      if (hasInternet) {
        syncPendingGrievances(); // Automatically triggers when internet returns
      }
    });
  }

  // Renamed to perfectly match what main_screen.dart is calling on line 96
  Future<void> syncPendingGrievances() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final List<Map<String, dynamic>> unsyncedRows = await DBHelper().getUnsyncedGrievances();
      if (unsyncedRows.isEmpty) {
        _isSyncing = false;
        return;
      }

      final url = Uri.parse('http://$_serverIp:$_port/api/grievances');

      for (var row in unsyncedRows) {
        int id = row['id'];
        var request = http.MultipartRequest('POST', url);
        
        // Append text fields
        request.fields['user_id'] = row['user_id'];
        request.fields['description'] = row['description'];
        request.fields['latitude'] = row['latitude'].toString();
        request.fields['longitude'] = row['longitude'].toString();
        request.fields['timestamp'] = row['timestamp'];

        // Append image file if present and valid
        String imagePath = row['image_path'];
        if (imagePath.isNotEmpty && await File(imagePath).exists()) {
          request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        }

        // Send request to FastAPI backend
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Successfully synced, update SQLite record status
          await DBHelper().markAsSynced(id);
        }
      }
    } catch (e) {
      print('Background sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
}