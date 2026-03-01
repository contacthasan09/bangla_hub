import 'package:flutter/material.dart';

class AdminJobsScreen extends StatelessWidget {
  const AdminJobsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 100,
              color: Color(0xFFFF9800),
            ),
            SizedBox(height: 20),
            Text(
              'Jobs Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF9800),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Job management content will appear here',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}