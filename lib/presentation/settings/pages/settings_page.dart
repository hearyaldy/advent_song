// lib/presentation/settings/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/theme_notifier.dart';
import '../../../core/services/favorites_notifier.dart';

class SettingsPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  final FavoritesNotifier? favoritesNotifier;

  const SettingsPage({
    super.key,
    required this.themeNotifier,
    this.favoritesNotifier,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _fontSize = 16.0;
  String _fontFamily = 'Roboto';
  TextAlign _textAlign = TextAlign.left;
  bool _isLoading = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _fontSize = prefs.getDouble('fontSize') ?? 16.0;
        _fontFamily = prefs.getString('fontFamily') ?? 'Roboto';
        _textAlign = TextAlign.values[prefs.getInt('textAlign') ?? 0];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setString('fontFamily', _fontFamily);
    await prefs.setInt('textAlign', _textAlign.index);

    if (mounted) {
      setState(() {
        _hasUnsavedChanges = false;
      });
      _showMessage('Settings saved successfully', isSuccess: true);
    }
  }

  Future<void> _resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      setState(() {
        _fontSize = 16.0;
        _fontFamily = 'Roboto';
        _textAlign = TextAlign.left;
        _hasUnsavedChanges = false;
      });

      await widget.themeNotifier.resetToDefaults();
      _showMessage('Settings have been reset to default', isSuccess: true);
    }
  }

  void _onSettingChanged() {
    if (!_hasUnsavedChanges && mounted) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<bool> _handlePop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content:
            const Text('You have unsaved changes. Save them before leaving?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard')),
          FilledButton(
            onPressed: () async {
              await _saveSettings();
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _showMessage(String message,
      {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : (isSuccess ? Colors.green.shade600 : null),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _handlePop();
        if (shouldPop && mounted) {
          context.go('/');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _handlePop();
              if (shouldPop && mounted) context.go('/');
            },
          ),
          actions: [
            if (_hasUnsavedChanges)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilledButton(
                    onPressed: _saveSettings, child: const Text('Save')),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- Text Display Section ---
            _buildSectionHeader('Text Display', Icons.text_fields_rounded),
            const SizedBox(height: 16),
            _buildFontSizeSlider(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _buildFontFamilySelector(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _buildTextAlignmentSelector(),

            const SizedBox(height: 24),

            // --- Appearance Section ---
            _buildSectionHeader('Appearance', Icons.palette_rounded),
            const SizedBox(height: 16),
            _buildDarkModeSwitch(),
            const Divider(height: 32, indent: 16, endIndent: 16),
            _buildColorThemeSelector(),

            const SizedBox(height: 24),

            // --- Preview Section ---
            _buildSectionHeader('Preview', Icons.preview_rounded),
            const SizedBox(height: 16),
            _buildPreviewPane(),

            const SizedBox(height: 32),

            // --- Reset Button ---
            Center(
              child: TextButton.icon(
                onPressed: _showResetDialog,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset All Settings to Default'),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
              ),
            ),

            // --- Debug Section (only show in debug mode) ---
            if (kDebugMode && widget.favoritesNotifier != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              _buildSectionHeader(
                  'Debug Information', Icons.bug_report_rounded),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer
                    .withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorites Debug Info',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<Map<String, dynamic>>(
                        future: widget.favoritesNotifier!.getDiagnosticInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final info = snapshot.data!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDebugRow('Total Favorites',
                                    '${info['favorites_count']}'),
                                _buildDebugRow(
                                    'Last Save Time', info['last_save_time']),
                                _buildDebugRow(
                                    'Migration Status',
                                    info['migration_completed']
                                        ? 'Completed'
                                        : 'Pending'),
                                _buildDebugRow(
                                    'Version', '${info['favorites_version']}'),
                                _buildDebugRow('Has Backup',
                                    info['has_backup'] ? 'Yes' : 'No'),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () async {
                                        final restored = await widget
                                            .favoritesNotifier!
                                            .restoreFromBackup();
                                        _showMessage(
                                          restored
                                              ? 'Favorites restored from backup'
                                              : 'No backup found',
                                          isSuccess: restored,
                                        );
                                      },
                                      child: const Text('Restore Backup'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () async {
                                        await widget.favoritesNotifier!
                                            .validateFavorites();
                                        _showMessage('Favorites validated',
                                            isSuccess: true);
                                      },
                                      child: const Text('Validate Data'),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(title,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFontSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Font Size'),
            const Spacer(),
            Text('${_fontSize.toInt()}px',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        Slider(
          value: _fontSize,
          min: AppConstants.minFontSize,
          max: AppConstants.maxFontSize,
          divisions: 12,
          onChanged: (value) {
            setState(() => _fontSize = value);
            _onSettingChanged();
          },
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector() {
    const fontFamilies = [
      'Roboto',
      'Georgia',
      'Times New Roman',
      'Courier New'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Font Family'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: fontFamilies.map((font) {
            final isSelected = _fontFamily == font;
            return ChoiceChip(
              label: Text(font, style: TextStyle(fontFamily: font)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _fontFamily = font);
                  _onSettingChanged();
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : null),
              shape: const StadiumBorder(),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTextAlignmentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Text Alignment'),
        const SizedBox(height: 12),
        SegmentedButton<TextAlign>(
          segments: const [
            ButtonSegment(
                value: TextAlign.left,
                icon: Icon(Icons.format_align_left_rounded)),
            ButtonSegment(
                value: TextAlign.center,
                icon: Icon(Icons.format_align_center_rounded)),
            ButtonSegment(
                value: TextAlign.right,
                icon: Icon(Icons.format_align_right_rounded)),
          ],
          selected: {_textAlign},
          onSelectionChanged: (newSelection) {
            setState(() => _textAlign = newSelection.first);
            _onSettingChanged();
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            selectedBackgroundColor: Theme.of(context).colorScheme.primary,
            selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDarkModeSwitch() {
    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: widget.themeNotifier.isDarkMode,
      onChanged: (value) async {
        await widget.themeNotifier.updateDarkMode(value);
        _onSettingChanged();
      },
      secondary: Icon(widget.themeNotifier.isDarkMode
          ? Icons.dark_mode_rounded
          : Icons.light_mode_rounded),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildColorThemeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color Theme'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.themeNotifier.availableColorThemes.map((themeKey) {
            final themeData = widget.themeNotifier.getColorThemeData(themeKey)!;
            final isSelected =
                widget.themeNotifier.selectedColorTheme == themeKey;
            final primaryColor = themeData['primary'] as Color;

            return GestureDetector(
              onTap: () async {
                if (!isSelected) {
                  await widget.themeNotifier.updateColorTheme(themeKey);
                  _onSettingChanged();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: primaryColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreviewPane() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Text(
        'This is how your song lyrics will appear with the current settings.',
        style: TextStyle(
          fontSize: _fontSize,
          fontFamily: _fontFamily,
          height: 1.5,
        ),
        textAlign: _textAlign,
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
            'Are you sure you want to reset all settings to their default values?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _resetSettings();
            },
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
