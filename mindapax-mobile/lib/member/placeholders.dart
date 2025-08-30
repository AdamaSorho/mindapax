import 'package:flutter/material.dart';
import 'member_scaffold.dart';

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String route;
  const PlaceholderPage({super.key, required this.title, required this.route});

  @override
  Widget build(BuildContext context) {
    return MemberScaffold(
      title: title,
      currentRoute: route,
      child: Center(
        child: Text('$title is coming soon', style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
