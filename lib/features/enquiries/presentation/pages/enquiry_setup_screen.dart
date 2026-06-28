import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/enquiry_options_repository.dart';
import '../../data/repositories/enquiry_fields_repository.dart';
import '../providers/enquiry_options_provider.dart';
import '../providers/enquiry_fields_provider.dart';

/// Admin setup for enquiries:
///  - Option lists (Nature of Enquiry, Nationality, Rejection Reasons)
///  - Custom fields (admin-defined fields the enquiry form collects)
class EnquirySetupScreen extends ConsumerStatefulWidget {
  const EnquirySetupScreen({super.key});

  @override
  ConsumerState<EnquirySetupScreen> createState() => _EnquirySetupScreenState();
}

const _kFieldsTab = '__fields__';

class _EnquirySetupScreenState extends ConsumerState<EnquirySetupScreen> {
  static const _tabs = <(String, String)>[
    (EnquiryOptionCategory.nature, 'Nature of Enquiry'),
    (EnquiryOptionCategory.nationality, 'Nationality'),
    (EnquiryOptionCategory.rejectionReason, 'Rejection Reasons'),
    (_kFieldsTab, 'Custom Fields'),
  ];

  String _tab = EnquiryOptionCategory.nature;

  EnquiryOptionsRepository get _optRepo => ref.read(enquiryOptionsRepositoryProvider);
  EnquiryFieldsRepository get _fieldRepo => ref.read(enquiryFieldsRepositoryProvider);

  bool get _isFieldsTab => _tab == _kFieldsTab;

  void _refreshOptions() {
    ref.invalidate(enquiryOptionRowsProvider(_tab));
    ref.invalidate(enquiryOptionValuesProvider(_tab));
  }

  void _refreshFields() {
    ref.invalidate(enquiryFieldRowsProvider);
    ref.invalidate(activeEnquiryFieldsProvider);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
    );
  }

  // ── Option list actions ──────────────────────────────────────────────────
  Future<void> _addOrRenameOption({EnquiryOption? existing}) async {
    final ctrl = TextEditingController(text: existing?.value ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add option' : 'Rename option'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter value'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result == null || result.isEmpty) return;
    try {
      if (existing == null) {
        await _optRepo.addOption(_tab, result);
      } else {
        await _optRepo.renameOption(existing.id, result);
      }
      _refreshOptions();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteOption(EnquiryOption o) async {
    final ok = await _confirm('Remove option?', 'Remove "${o.value}"? Existing enquiries are not affected.');
    if (!ok) return;
    try {
      await _optRepo.deleteOption(o.id);
      _refreshOptions();
    } catch (e) {
      _showError(e);
    }
  }

  // ── Custom field actions ─────────────────────────────────────────────────
  Future<void> _addOrEditField({EnquiryField? existing}) async {
    final result = await showDialog<_FieldDraft>(
      context: context,
      builder: (_) => _FieldDialog(existing: existing),
    );
    if (result == null) return;
    try {
      if (existing == null) {
        await _fieldRepo.addField(
          label: result.label,
          fieldType: result.type,
          required: result.required,
          options: result.options,
        );
      } else {
        await _fieldRepo.updateField(
          existing.id,
          label: result.label,
          fieldType: result.type,
          required: result.required,
          options: result.options,
        );
      }
      _refreshFields();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggleField(EnquiryField f, bool active) async {
    try {
      await _fieldRepo.updateField(f.id, isActive: active);
      _refreshFields();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteField(EnquiryField f) async {
    final ok = await _confirm('Remove field?',
        'Remove "${f.label}"? It will no longer be collected. Values already saved on existing enquiries remain in the database.');
    if (!ok) return;
    try {
      await _fieldRepo.deleteField(f.id);
      _refreshFields();
    } catch (e) {
      _showError(e);
    }
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Enquiry Setup')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _isFieldsTab ? _addOrEditField() : _addOrRenameOption(),
        backgroundColor: AppTheme.electricBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_isFieldsTab ? 'Add field' : 'Add option',
            style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _tabs.map((c) {
                  final selected = _tab == c.$1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c.$2),
                      selected: selected,
                      onSelected: (_) => setState(() => _tab = c.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _isFieldsTab
                    ? 'Extra fields collected on the New Enquiry form for your organization.'
                    : 'These choices appear in the New Enquiry form. Disable to hide without deleting.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Expanded(child: _isFieldsTab ? _buildFieldsList(isDark) : _buildOptionsList(isDark)),
        ],
      ),
    );
  }

  Widget _buildOptionsList(bool isDark) {
    final rowsAsync = ref.watch(enquiryOptionRowsProvider(_tab));
    return rowsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('No options yet — tap "Add option".', style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final o = rows[i];
            return _card(isDark, ListTile(
              title: Text(o.value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: o.isActive ? (isDark ? Colors.white : AppTheme.darkBlue) : Colors.grey,
                    decoration: o.isActive ? null : TextDecoration.lineThrough,
                  )),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(
                  value: o.isActive,
                  activeThumbColor: AppTheme.emeraldGreen,
                  onChanged: (v) async {
                    try {
                      await _optRepo.setActive(o.id, v);
                      _refreshOptions();
                    } catch (e) {
                      _showError(e);
                    }
                  },
                ),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _addOrRenameOption(existing: o)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed), onPressed: () => _deleteOption(o)),
              ]),
            ));
          },
        );
      },
    );
  }

  Widget _buildFieldsList(bool isDark) {
    final fieldsAsync = ref.watch(enquiryFieldRowsProvider);
    return fieldsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (fields) {
        if (fields.isEmpty) {
          return const Center(child: Text('No custom fields yet — tap "Add field".', style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          itemCount: fields.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final f = fields[i];
            final meta = '${EnquiryFieldType.label(f.fieldType)}${f.required ? ' · required' : ''}'
                '${f.fieldType == EnquiryFieldType.dropdown ? ' · ${f.options.length} options' : ''}';
            return _card(isDark, ListTile(
              title: Text(f.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: f.isActive ? (isDark ? Colors.white : AppTheme.darkBlue) : Colors.grey,
                    decoration: f.isActive ? null : TextDecoration.lineThrough,
                  )),
              subtitle: Text(meta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(value: f.isActive, activeThumbColor: AppTheme.emeraldGreen, onChanged: (v) => _toggleField(f, v)),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _addOrEditField(existing: f)),
                IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed), onPressed: () => _deleteField(f)),
              ]),
            ));
          },
        );
      },
    );
  }

  Widget _card(bool isDark, Widget child) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
        ),
        child: child,
      );
}

// ── Add/Edit custom field dialog ───────────────────────────────────────────

class _FieldDraft {
  final String label;
  final String type;
  final bool required;
  final List<String> options;
  _FieldDraft(this.label, this.type, this.required, this.options);
}

class _FieldDialog extends StatefulWidget {
  final EnquiryField? existing;
  const _FieldDialog({this.existing});

  @override
  State<_FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<_FieldDialog> {
  late final TextEditingController _label;
  late final TextEditingController _options;
  late String _type;
  late bool _required;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = TextEditingController(text: e?.label ?? '');
    _options = TextEditingController(text: e?.options.join(', ') ?? '');
    _type = e?.fieldType ?? EnquiryFieldType.text;
    _required = e?.required ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _options.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add field' : 'Edit field'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _label,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Field label'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: EnquiryFieldType.all
                .map((t) => DropdownMenuItem(value: t, child: Text(EnquiryFieldType.label(t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? EnquiryFieldType.text),
          ),
          if (_type == EnquiryFieldType.dropdown) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _options,
              decoration: const InputDecoration(
                labelText: 'Options (comma separated)',
                hintText: 'e.g. Small, Medium, Large',
              ),
            ),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Required'),
            value: _required,
            activeThumbColor: AppTheme.emeraldGreen,
            onChanged: (v) => setState(() => _required = v),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final label = _label.text.trim();
            if (label.isEmpty) return;
            final opts = _type == EnquiryFieldType.dropdown
                ? _options.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
                : <String>[];
            Navigator.pop(context, _FieldDraft(label, _type, _required, opts));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
