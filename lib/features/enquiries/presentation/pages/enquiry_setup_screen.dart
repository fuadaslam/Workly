import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/repositories/enquiry_options_repository.dart';
import '../providers/enquiry_options_provider.dart';

/// Admin setup for the org-level enquiry dropdown options. Lets an admin add,
/// rename, enable/disable, and remove the choices shown when creating an
/// enquiry (Nature of Enquiry, Nationality, Rejection Reasons).
class EnquirySetupScreen extends ConsumerStatefulWidget {
  const EnquirySetupScreen({super.key});

  @override
  ConsumerState<EnquirySetupScreen> createState() => _EnquirySetupScreenState();
}

class _EnquirySetupScreenState extends ConsumerState<EnquirySetupScreen> {
  static const _categories = <(String, String)>[
    (EnquiryOptionCategory.nature, 'Nature of Enquiry'),
    (EnquiryOptionCategory.nationality, 'Nationality'),
    (EnquiryOptionCategory.rejectionReason, 'Rejection Reasons'),
  ];

  String _category = EnquiryOptionCategory.nature;

  EnquiryOptionsRepository get _repo => ref.read(enquiryOptionsRepositoryProvider);

  void _refresh() {
    ref.invalidate(enquiryOptionRowsProvider(_category));
    ref.invalidate(enquiryOptionValuesProvider(_category));
  }

  Future<void> _addOrRename({EnquiryOption? existing}) async {
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
        await _repo.addOption(_category, result);
      } else {
        await _repo.renameOption(existing.id, result);
      }
      _refresh();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _delete(EnquiryOption option) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove option?'),
        content: Text('Remove "${option.value}"? Existing enquiries that already use it are not affected.'),
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
    if (ok != true) return;
    try {
      await _repo.deleteOption(option.id);
      _refresh();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _toggle(EnquiryOption option, bool active) async {
    try {
      await _repo.setActive(option.id, active);
      _refresh();
    } catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rowsAsync = ref.watch(enquiryOptionRowsProvider(_category));

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.backgroundLight,
      appBar: AppBar(title: const Text('Enquiry Setup')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrRename(),
        backgroundColor: AppTheme.electricBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add option', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _categories.map((c) {
                  final selected = _category == c.$1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(c.$2),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = c.$1),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'These choices appear in the New Enquiry form for your organization. '
                'Disable to hide without deleting.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: rowsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (rows) {
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('No options yet — tap "Add option".',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final o = rows[i];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isDark
                            ? []
                            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: ListTile(
                        title: Text(
                          o.value,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: o.isActive
                                ? (isDark ? Colors.white : AppTheme.darkBlue)
                                : Colors.grey,
                            decoration: o.isActive ? null : TextDecoration.lineThrough,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: o.isActive,
                              activeThumbColor: AppTheme.emeraldGreen,
                              onChanged: (v) => _toggle(o, v),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _addOrRename(existing: o),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.errorRed),
                              onPressed: () => _delete(o),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
