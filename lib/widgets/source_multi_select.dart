import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';

class SourceMultiSelect extends ConsumerStatefulWidget {
  const SourceMultiSelect({super.key});

  @override
  ConsumerState<SourceMultiSelect> createState() => _SourceMultiSelectState();
}

class _SourceMultiSelectState extends ConsumerState<SourceMultiSelect> {
  final List<String> _allSources = ['YouTube', 'MediaMonkey'];

  @override
  void initState() {
    super.initState();
  }

  void _showSelectionDialog() {
    // Create a local mutable copy for the dialog state
    Set<String> localSelected = Set.from(ref.read(selectedSourcesProvider));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              title: const Text('Select Sources', style: TextStyle(color: AppTheme.textMain)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      title: const Text('All Sources', style: TextStyle(color: Colors.white)),
                      value: localSelected.length == _allSources.length,
                      activeColor: AppTheme.accentPurple,
                      checkColor: Colors.white,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            localSelected = Set.from(_allSources);
                          } else {
                            localSelected.clear();
                          }
                          ref.read(selectedSourcesProvider.notifier).setSources(localSelected);
                        });
                      },
                    ),
                    const Divider(color: AppTheme.border),
                    ..._allSources.map((source) {
                      return CheckboxListTile(
                        title: Text(source, style: const TextStyle(color: AppTheme.textMuted)),
                        value: localSelected.contains(source),
                        activeColor: AppTheme.accentPurple,
                        checkColor: Colors.white,
                        onChanged: (bool? checked) {
                          setStateDialog(() {
                            if (checked == true) {
                              localSelected.add(source);
                            } else {
                              localSelected.remove(source);
                            }
                            ref.read(selectedSourcesProvider.notifier).setSources(localSelected);
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done', style: TextStyle(color: AppTheme.accentPurpleLight)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentSelected = ref.watch(selectedSourcesProvider);
    String label = currentSelected.length == _allSources.length 
        ? 'All Sources' 
        : '${currentSelected.length} Sources';

    return InkWell(
      onTap: _showSelectionDialog,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgInput,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
