import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/database.dart';
import '../models/enums.dart';

/// Exception thrown when an imported file isn't a recognisable BetBook backup.
class InvalidBackupException implements Exception {
  const InvalidBackupException();
}

/// Handles JSON backup (round-trip) and CSV export (spreadsheet-friendly).
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const int backupFormatVersion = 1;

  /// Serialises the whole database to a pretty JSON string.
  Future<String> buildBackupJson({required String baseCurrency}) async {
    final sites = await _db.getSites();
    final txs = await _db.getAllTransactions();
    final rates = await _db.getRates();

    final map = {
      'app': 'BetBook',
      'formatVersion': backupFormatVersion,
      'baseCurrency': baseCurrency,
      'sites': [
        for (final s in sites)
          {
            'id': s.id,
            'name': s.name,
            'currencyCode': s.currencyCode,
            'colorValue': s.colorValue,
            'iconCodePoint': s.iconCodePoint,
            'sortOrder': s.sortOrder,
            'createdAt': s.createdAt.toIso8601String(),
          },
      ],
      'transactions': [
        for (final t in txs)
          {
            'id': t.id,
            'siteId': t.siteId,
            'type': t.type.index,
            'amountMinor': t.amountMinor,
            'date': t.date.toIso8601String(),
            'note': t.note,
            'createdAt': t.createdAt.toIso8601String(),
          },
      ],
      'rates': [
        for (final r in rates)
          {
            'currencyCode': r.currencyCode,
            'rateToBase': r.rateToBase,
            'updatedAt': r.updatedAt.toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  /// Writes a JSON backup to a temp file and returns it, ready to be shared.
  Future<File> writeBackupFile({required String baseCurrency}) async {
    final json = await buildBackupJson(baseCurrency: baseCurrency);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File(p.join(dir.path, 'betbook-backup-$stamp.json'));
    return file.writeAsString(json);
  }

  /// Writes a transactions CSV (joined with site names) and returns it.
  Future<File> writeTransactionsCsv() async {
    final sites = await _db.getSites();
    final byId = {for (final s in sites) s.id: s};
    final txs = await _db.getAllTransactions();

    final rows = <List<dynamic>>[
      ['Date', 'Site', 'Currency', 'Type', 'Amount', 'Note'],
      for (final t in txs)
        [
          t.date.toIso8601String(),
          byId[t.siteId]?.name ?? t.siteId,
          byId[t.siteId]?.currencyCode ?? '',
          t.type.name,
          (t.amountMinor / 100).toStringAsFixed(2),
          t.note ?? '',
        ],
    ];

    final csv = rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File(p.join(dir.path, 'betbook-transactions-$stamp.csv'));
    return file.writeAsString(csv);
  }

  /// Quotes a CSV cell, escaping embedded quotes, per RFC 4180.
  String _csvCell(dynamic value) {
    final s = '$value';
    if (s.contains(',') || s.contains('"') || s.contains('\n') ||
        s.contains('\r')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  /// Parses [json] and atomically replaces all current data. Throws
  /// [InvalidBackupException] if the structure isn't a BetBook backup.
  Future<void> importFromJson(String json) async {
    late final Map<String, dynamic> map;
    try {
      map = jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      throw const InvalidBackupException();
    }

    if (map['app'] != 'BetBook' ||
        map['sites'] is! List ||
        map['transactions'] is! List) {
      throw const InvalidBackupException();
    }

    try {
      final sites = [
        for (final raw in (map['sites'] as List).cast<Map<String, dynamic>>())
          SitesCompanion.insert(
            id: raw['id'] as String,
            name: raw['name'] as String,
            currencyCode: raw['currencyCode'] as String,
            colorValue: (raw['colorValue'] as num).toInt(),
            iconCodePoint: Value(
                (raw['iconCodePoint'] as num?)?.toInt()),
            sortOrder: Value((raw['sortOrder'] as num?)?.toInt() ?? 0),
            createdAt: DateTime.parse(raw['createdAt'] as String),
          ),
      ];

      final txs = [
        for (final raw
            in (map['transactions'] as List).cast<Map<String, dynamic>>())
          TransactionsCompanion.insert(
            id: raw['id'] as String,
            siteId: raw['siteId'] as String,
            type: TransactionType.values[(raw['type'] as num).toInt()],
            amountMinor: (raw['amountMinor'] as num).toInt(),
            date: DateTime.parse(raw['date'] as String),
            note: Value(raw['note'] as String?),
            createdAt: DateTime.parse(raw['createdAt'] as String),
          ),
      ];

      final rates = [
        for (final raw
            in ((map['rates'] as List?) ?? const []).cast<Map<String, dynamic>>())
          ExchangeRatesCompanion.insert(
            currencyCode: raw['currencyCode'] as String,
            rateToBase: (raw['rateToBase'] as num).toDouble(),
            updatedAt: DateTime.parse(raw['updatedAt'] as String),
          ),
      ];

      await _db.replaceAll(
        newSites: sites,
        newTransactions: txs,
        newRates: rates,
      );
    } catch (_) {
      throw const InvalidBackupException();
    }
  }
}
