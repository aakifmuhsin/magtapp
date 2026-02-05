import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Settings',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text('Theme'),
          subtitle: Text('Uses system theme (light / dark)'),
        ),
        ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('About'),
          subtitle: Text('MagTapp AI Browser - demo assignment build'),
        ),
      ],
    );
  }
}

