import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SourceMultiSelect extends StatefulWidget {
  const SourceMultiSelect({super.key});

  @override
  State<SourceMultiSelect> createState() => _SourceMultiSelectState();
}

class _SourceMultiSelectState extends State<SourceMultiSelect> {
  final List<String> _allSources = ['YouTube', 'MediaMonkey', 'Local Files', 'Smule'];
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(_allSources);
  }

  void _showSelectionDialog() {
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
                      value: _selected.length == _allSources.length,
                      activeColor: AppTheme.accentPurple,
                      checkColor: Colors.white,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked == true) {
                            _selected = Set.from(_allSources);
                          } else {
                            _selected.clear();
                          }
                        });
                        setState(() {});
                      },
                    ),
                    const Divider(color: AppTheme.border),
                    ..._allSources.map((source) {
                      return CheckboxListTile(
                        title: Text(source, style: const TextStyle(color: AppTheme.textMuted)),
                        value: _selected.contains(source),
                        activeColor: AppTheme.accentPurple,
                        checkColor: Colors.white,
                        onChanged: (bool? checked) {
                          setStateDialog(() {
                            if (checked == true) {
                              _selected.add(source);
                            } else {
                              _selected.remove(source);
                            }
                          });
                          setState(() {});
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
    String label = _selected.length == _allSources.length 
        ? 'All Sources' 
        : '${_selected.length} Sources';

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
