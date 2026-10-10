import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Controlla l'ultima release su GitHub e propone di scaricare l'APK se e piu nuova.
/// Solo Android. Uso: Updater.check(context) all'avvio della home.
class Updater {
  static const _repo = 'ZenigataBloch/Kino_Oracle';
  static bool _done = false; // una sola proposta per sessione

  static Future<void> check(BuildContext context) async {
    if (_done || kIsWeb || !Platform.isAndroid) return;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final req = await client.getUrl(Uri.https('api.github.com', '/repos/$_repo/releases/latest'));
      req.headers.set('Accept', 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final j = jsonDecode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;

      final tag = (j['tag_name'] as String?) ?? '';
      String? apk;
      for (final a in (j['assets'] as List?) ?? const []) {
        final name = (a['name'] as String?) ?? '';
        if (name.endsWith('.apk')) {
          apk = a['browser_download_url'] as String?;
          break;
        }
      }
      if (apk == null) return;

      final current = (await PackageInfo.fromPlatform()).version;
      if (!_newer(tag, current)) return;
      if (!context.mounted) return;
      _done = true;

      final notes = ((j['body'] as String?) ?? '').trim();
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Aggiornamento disponibile'),
          content: Text(
            'Nuova versione ${tag.replaceFirst(RegExp(r'^[vV]'), '')} '
            '(hai la $current).${notes.isEmpty ? '' : '\n\n$notes'}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Più tardi')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Scarica')),
          ],
        ),
      );
      if (go == true) await launchUrl(Uri.parse(apk), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Niente rete o GitHub non raggiungibile: si gioca e basta.
    } finally {
      client.close();
    }
  }

  static List<int> _parse(String s) => s
      .replaceFirst(RegExp(r'^[vV]'), '')
      .split('+')
      .first
      .split('.')
      .map((e) => int.tryParse(RegExp(r'^\d+').firstMatch(e)?.group(0) ?? '') ?? 0) // '4b' -> 4
      .toList();

  static bool _newer(String a, String b) {
    final x = _parse(a), y = _parse(b);
    for (var i = 0; i < 3; i++) {
      final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
      if (p != q) return p > q;
    }
    return false;
  }
}
