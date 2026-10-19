import 'dart:io';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class MyGrievancesScreen extends StatefulWidget {
  const MyGrievancesScreen({super.key});

  @override
  State<MyGrievancesScreen> createState() => _MyGrievancesScreenState();
}

class _MyGrievancesScreenState extends State<MyGrievancesScreen> {
  late Future<List<Map<String, dynamic>>> _grievancesList;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      // Fetch all grievances using the correct method name
      _grievancesList = DBHelper().getAllGrievances();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Submissions'),
        backgroundColor: Colors.teal[800],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _grievancesList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No grievances submitted yet.'));
          }

          final grievances = snapshot.data!;

          return ListView.builder(
            itemCount: grievances.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final item = grievances[index];
              final isSynced = item['sync_status'] == 1;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: ListTile(
                  leading: item['image_path'] != null && File(item['image_path']).existsSync()
                      ? Image.file(File(item['image_path']), width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported, size: 50),
                  title: Text(
                    item['description'], 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Date: ${item['timestamp'].toString().split('T')[0]}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSynced ? Icons.check_circle : Icons.cloud_upload,
                        color: isSynced ? Colors.green : Colors.orange,
                      ),
                      Text(
                        isSynced ? 'Synced' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSynced ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}