import 'package:flutter/material.dart';

/// Ekran ustawień (prosty placeholder, można rozbudować)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ustawienia gry',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sports_esports),
              title: const Text('Czułość sterowania'),
              subtitle: const Text('Wkrótce dostępne'),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.volume_up),
              title: const Text('Dźwięki'),
              subtitle: const Text('Wkrótce dostępne'),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}


