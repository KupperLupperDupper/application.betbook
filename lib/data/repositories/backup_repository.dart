import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/money/money_format.dart';
import '../database/database.dart';
import '../models/enums.dart';

/// Exception thrown when an imported file isn't a recognisable BetBook backup.
class InvalidBackupException implements Exception {
  const InvalidBackupException();
}

/// Outcome of an additive CSV import, for surfacing in the UI.
class CsvImportResult {
  const CsvImportResult({
    required this.transactionsAdded,
    required this.sitesCreated,
    required this.skippedRows,
  });

  final int transactionsAdded;
  final int sitesCreated;
  final int skippedRows;
}

/// Handles JSON backup (round-trip) and CSV export (spreadsheet-friendly).
class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  static const int backupFormatVersion = 1;
  static const _uuid = Uuid();

  /// Fallback palette for sites created during CSV import (matches the
  /// site-editor swatches). Cycled by creation order.
  static const List<int> _importColors = [
    0xFF3E5CF0, 0xFF1B7F52, 0xFFB3261E, 0xFFF29D38,
    0xFF7B4DFF, 0xFF00897B, 0xFFD5384B, 0xFF546E7A,
  ];

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

  /// Imports transactions from a CSV in the same shape [writeTransactionsCsv]
  /// produces (`Date, Site, Currency, Type, Amount, Note`). This is **additive**
  /// — existing data is untouched, sites are matched by name (case-insensitive)
  /// and created when missing. Unparseable rows are skipped and counted.
  ///
  /// Throws [InvalidBackupException] only when nothing usable could be read.
  Future<CsvImportResult> importTransactionsCsv(
    String csv, {
    required String baseCurrency,
  }) async {
    final rows = _parseCsv(csv);
    if (rows.isEmpty) throw const InvalidBackupException();

    // Skip a header row (first cell not a date).
    var start = 0;
    if (_tryDate(rows.first.isEmpty ? '' : rows.first.first) == null) start = 1;

    final existing = await _db.getSites();
    final byName = {for (final s in existing) s.name.toLowerCase(): s.id};
    final createdId = <String, String>{};
    final createdCurrency = <String, String>{};
    final newSites = <SitesCompanion>[];
    final newTxs = <TransactionsCompanion>[];
    final now = DateTime.now();
    var skipped = 0;
    var order = existing.length;

    for (var i = start; i < rows.length; i++) {
      final r = rows[i];
      if (r.every((c) => c.trim().isEmpty)) continue; // blank line
      if (r.length < 5) {
        skipped++;
        continue;
      }
      final date = _tryDate(r[0]);
      final siteName = r[1].trim();
      final currency = r.length > 2 ? r[2].trim().toUpperCase() : '';
      final type = _tryType(r[3]);
      final amount = _tryAmountMinor(r[4]);
      final note = r.length > 5 ? r[5].trim() : '';

      if (date == null || siteName.isEmpty || type == null || amount == null) {
        skipped++;
        continue;
      }

      final key = siteName.toLowerCase();
      var siteId = byName[key] ?? createdId[key];
      if (siteId == null) {
        siteId = _uuid.v4();
        createdId[key] = siteId;
        final cur = _isCurrencyCode(currency) ? currency : baseCurrency;
        createdCurrency[cur] = cur;
        newSites.add(
          SitesCompanion.insert(
            id: siteId,
            name: siteName,
            currencyCode: cur,
            colorValue: _importColors[order % _importColors.length],
            sortOrder: Value(order),
            createdAt: now,
          ),
        );
        order++;
      }

      newTxs.add(
        TransactionsCompanion.insert(
          id: _uuid.v4(),
          siteId: siteId,
          type: type,
          amountMinor: amount,
          date: date,
          note: Value(note.isEmpty ? null : note),
          createdAt: now,
        ),
      );
    }

    if (newTxs.isEmpty) throw const InvalidBackupException();

    // Every new site's currency needs an editable rate row.
    for (final cur in createdCurrency.keys) {
      await _db.ensureRate(cur, now);
    }
    await _db.addImported(newSites: newSites, newTransactions: newTxs);

    return CsvImportResult(
      transactionsAdded: newTxs.length,
      sitesCreated: newSites.length,
      skippedRows: skipped,
    );
  }

  /// Minimal RFC-4180 CSV reader: handles quoted fields, escaped `""` quotes,
  /// commas and newlines inside quotes, and both `\r\n` and `\n` line endings.
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    var field = StringBuffer();
    var row = <String>[];
    var inQuotes = false;
    var sawAny = false;

    void endField() {
      row.add(field.toString());
      field = StringBuffer();
    }

    void endRow() {
      endField();
      rows.add(row);
      row = <String>[];
      sawAny = false;
    }

    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(c);
        }
      } else if (c == '"') {
        inQuotes = true;
        sawAny = true;
      } else if (c == ',') {
        sawAny = true;
        endField();
      } else if (c == '\n' || c == '\r') {
        if (c == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        if (sawAny || field.isNotEmpty || row.isNotEmpty) endRow();
      } else {
        sawAny = true;
        field.write(c);
      }
    }
    if (sawAny || field.isNotEmpty || row.isNotEmpty) endRow();
    return rows;
  }

  static DateTime? _tryDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  static TransactionType? _tryType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'deposit':
      case 'indbetaling':
        return TransactionType.deposit;
      case 'withdrawal':
      case 'udbetaling':
        return TransactionType.withdrawal;
      default:
        return null;
    }
  }

  /// Parses a money cell to minor units, tolerating `.` or `,` decimals and
  /// grouping separators from spreadsheets in either locale.
  static int? _tryAmountMinor(String raw) {
    var s = raw.trim().replaceAll(' ', '');
    if (s.isEmpty) return null;
    final hasComma = s.contains(',');
    final hasDot = s.contains('.');
    if (hasComma && hasDot) {
      // The last separator is the decimal; the other groups thousands.
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (hasComma) {
      s = s.replaceAll(',', '.');
    }
    final value = double.tryParse(s);
    if (value == null) return null;
    return majorToMinor(value);
  }

  static bool _isCurrencyCode(String s) =>
      s.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(s);
}
