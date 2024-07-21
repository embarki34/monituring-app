import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../auth/sign_in_screen.dart';
import 'add_comment_screen.dart';
import 'chat_with_ai.dart';

class HomeScreen extends StatelessWidget {
  final _storage = const FlutterSecureStorage();

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreen()),
      (route) => false,
    );
  }

  Future<void> _sendEmergencyRequest(BuildContext context) async {
    final token = await _storage.read(key: 'token');
    final response = await http.post(
      Uri.parse(
          'https://honeybee-prime-supposedly.ngrok-free.app/emergency_call'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency request sent successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send emergency request.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _EmergencyTile(
                onTap: () => _sendEmergencyRequest(context),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.custom(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  childrenDelegate: SliverChildListDelegate(
                    [
                      _buildGridTile(
                          context, Icons.comment_bank_outlined, 'كيف تشعر الان',
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AddCommentScreen()),
                        );
                        // Navigate to Add Comment screen
                      }),
                      _buildGridTile(
                          context, Icons.chat_bubble_outline_sharp, 'محادثة',
                          () {
                        // Navigate to Analyze Chat screen
                      }),
                      // Add more tiles as needed
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridTile(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        if (title == 'محادثة') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                apiKey: 'AIzaSyBR1Bd15WLSuLleTwabOJ7sI17T5V6xWVw',
              ),
            ),
          );
        } else {
          onTap();
        }
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 130, 173, 247),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(icon, size: 50, color: Colors.white),
          ),
        ),
        footer: Container(
          child: Center(
            child: Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  final VoidCallback onTap;

  const _EmergencyTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 600,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'إرسال طلب الطوارئ',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
