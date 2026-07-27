import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';

class UpdateInfo {
  final String tagName;
  final String name;
  final String body;
  final String? downloadUrl;

  const UpdateInfo({
    required this.tagName,
    required this.name,
    required this.body,
    this.downloadUrl,
  });
}

class AppUpdater {
  static const String _repo = 'wegiel360/kogutopedia';
  static const String _currentVersion = '0.0.8.1-hotfix';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/$_repo/releases/latest',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      );
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';

      if (tagName.compareTo(_currentVersion) <= 0) return null;

      String? downloadUrl;
      final assets = data['assets'] as List?;
      if (assets != null && assets.isNotEmpty) {
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk') || name.endsWith('.zip')) {
            downloadUrl = asset['browser_download_url'] as String?;
            break;
          }
        }
      }

      return UpdateInfo(
        tagName: tagName,
        name: data['name'] as String? ?? tagName,
        body: data['body'] as String? ?? '',
        downloadUrl: downloadUrl,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> showUpdateDialog(
    BuildContext context,
    UpdateInfo update,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x8000F0FF), width: 0.5),
        ),
        title: const Text(
          'Dostępna aktualizacja',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nowa wersja: ${update.name}',
              style: const TextStyle(
                color: Color(0xFFFFB800),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              update.body,
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Później',
              style: TextStyle(color: Color(0x80FFFFFF)),
            ),
          ),
          if (update.downloadUrl != null)
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(update.downloadUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Pobierz',
                style: TextStyle(color: Color(0xFF00F0FF)),
              ),
            ),
        ],
      ),
    );
  }
}
