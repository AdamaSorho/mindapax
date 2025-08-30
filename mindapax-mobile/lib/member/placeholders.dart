import 'package:flutter/material.dart';
import 'menu.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String route;
  const PlaceholderPage({super.key, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: MemberDrawer(currentRoute: route),
      body: Center(
        child: Text('$title is coming soon', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

