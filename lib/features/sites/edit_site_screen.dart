import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money/currency.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';

/// Palette offered when creating a site.
const _siteColors = <int>[
  0xFF3E5CF0, 0xFF1B7F52, 0xFFB3261E, 0xFFF29D38,
  0xFF7B4DFF, 0xFF00897B, 0xFFD5384B, 0xFF546E7A,
];

class EditSiteScreen extends ConsumerStatefulWidget {
  const EditSiteScreen({super.key, this.siteId});

  final String? siteId;
  bool get isEditing => siteId != null;

  @override
  ConsumerState<EditSiteScreen> createState() => _EditSiteScreenState();
}

class _EditSiteScreenState extends ConsumerState<EditSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _currency = ref.read(settingsProvider).baseCurrency;
  int _color = _siteColors.first;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(siteRepositoryProvider);
    if (widget.isEditing) {
      await repo.updateSite(
        id: widget.siteId!,
        name: _nameController.text,
        currencyCode: _currency,
        colorValue: _color,
      );
    } else {
      await repo.createSite(
        name: _nameController.text,
        currencyCode: _currency,
        colorValue: _color,
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.siteDelete),
        content: Text(l10n.siteDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(siteRepositoryProvider).deleteSite(widget.siteId!);
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // Prefill once when editing.
    if (widget.isEditing && !_initialized) {
      final site = ref.watch(siteByIdProvider(widget.siteId!)).valueOrNull;
      if (site != null) {
        _nameController.text = site.name;
        _currency = site.currencyCode;
        _color = site.colorValue;
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.siteEdit : l10n.siteAdd),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: !widget.isEditing,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l10n.siteNameLabel,
                hintText: l10n.siteNameHint,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.commonRequired : null,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: InputDecoration(labelText: l10n.siteCurrencyLabel),
              items: [
                for (final c in kSupportedCurrencies)
                  DropdownMenuItem(
                    value: c.code,
                    child: Text('${c.code} · ${c.name}'),
                  ),
              ],
              onChanged: (v) => setState(() => _currency = v ?? _currency),
            ),
            const SizedBox(height: 24),
            Text(l10n.siteColorLabel,
                style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final c in _siteColors)
                  _ColorSwatch(
                    color: Color(c),
                    selected: c == _color,
                    onTap: () => setState(() => _color = c),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.actionSave),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface, width: 3)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check_rounded, color: Colors.white)
            : null,
      ),
    );
  }
}
