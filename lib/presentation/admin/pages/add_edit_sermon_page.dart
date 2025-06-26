// lib/presentation/admin/pages/add_edit_sermon_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/services/sermon_service.dart';

class AddEditSermonPage extends StatefulWidget {
  final Map<String, dynamic>? sermon; // null for add, sermon data for edit

  const AddEditSermonPage({super.key, this.sermon});

  @override
  State<AddEditSermonPage> createState() => _AddEditSermonPageState();
}

class _AddEditSermonPageState extends State<AddEditSermonPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _pastorController = TextEditingController();
  final _seriesController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool get _isEdit => widget.sermon != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _populateFields();
    }
  }

  void _populateFields() {
    final sermon = widget.sermon!;
    _titleController.text = sermon['title'] ?? '';
    _pastorController.text = sermon['pastor'] ?? '';
    _seriesController.text = sermon['series'] ?? '';
    _descriptionController.text = sermon['description'] ?? '';
    _durationController.text = sermon['duration']?.toString() ?? '';
    _audioUrlController.text = sermon['audioUrl'] ?? '';
    _videoUrlController.text = sermon['videoUrl'] ?? '';
    _selectedDate = sermon['date'] as DateTime? ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pastorController.dispose();
    _seriesController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  // --- THIS METHOD IS NOW CORRECTED ---
  Future<void> _saveSermon() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      // The service call now returns a simple boolean
      final bool wasSuccessful;

      if (_isEdit) {
        // The update call takes an ID and a Map, which was correct
        final data = {
          'title': _titleController.text.trim(),
          'pastor': _pastorController.text.trim(),
          'series': _seriesController.text.trim(),
          'description': _descriptionController.text.trim(),
          'duration': int.tryParse(_durationController.text.trim()) ?? 0,
          'audioUrl': _audioUrlController.text.trim(),
          'videoUrl': _videoUrlController.text.trim(),
          'hasAudio': _audioUrlController.text.trim().isNotEmpty,
          'hasVideo': _videoUrlController.text.trim().isNotEmpty,
          'date': _selectedDate,
        };
        wasSuccessful =
            await SermonService.updateSermon(widget.sermon!['id'], data);
      } else {
        // The add call takes named parameters, not a map. This is now fixed.
        wasSuccessful = await SermonService.addSermon(
          title: _titleController.text.trim(),
          pastor: _pastorController.text.trim(),
          date: _selectedDate,
          series: _seriesController.text.trim(),
          description: _descriptionController.text.trim(),
          duration: int.tryParse(_durationController.text.trim()) ?? 0,
          audioUrl: _audioUrlController.text.trim(),
          videoUrl: _videoUrlController.text.trim(),
        );
      }

      if (mounted) {
        // We now check the boolean directly
        if (wasSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit
                  ? 'Sermon updated successfully!'
                  : 'Sermon added successfully!'),
              backgroundColor: Colors.green.shade600,
            ),
          );
          context.go('/admin/sermons');
        } else {
          _showMessage('Failed to save sermon. Please try again.',
              isError: true);
        }
      }
    } catch (e) {
      _showMessage('An unexpected error occurred: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Sermon' : 'Add Sermon'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin/sermons'),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilledButton(
                    onPressed: _saveSermon,
                    child: Text(_isEdit ? 'Update' : 'Save'),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader(
                'Basic Information', Icons.info_outline_rounded),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _titleController,
              labelText: 'Sermon Title *',
              prefixIcon: Icons.title_rounded,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Title is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _pastorController,
              labelText: 'Pastor Name *',
              prefixIcon: Icons.person_rounded,
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Pastor name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _seriesController,
              labelText: 'Sermon Series (Optional)',
              prefixIcon: Icons.library_books_rounded,
            ),
            const Divider(height: 48),
            _buildSectionHeader(
                'Schedule & Details', Icons.calendar_month_rounded),
            const SizedBox(height: 16),
            _buildDatePickerField(),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _durationController,
              labelText: 'Duration (in minutes)',
              prefixIcon: Icons.timer_rounded,
              keyboardType: TextInputType.number,
            ),
            const Divider(height: 48),
            _buildSectionHeader('Content', Icons.article_rounded),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _descriptionController,
              labelText: 'Description',
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _audioUrlController,
              labelText: 'Audio URL (Optional)',
              prefixIcon: Icons.audiotrack_rounded,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _videoUrlController,
              labelText: 'Video URL (Optional)',
              prefixIcon: Icons.videocam_rounded,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveSermon,
              icon: _isLoading
                  ? Container()
                  : Icon(_isEdit
                      ? Icons.check_circle_outline_rounded
                      : Icons.add_circle_outline_rounded),
              label: Text(_isEdit ? 'Update Sermon' : 'Add Sermon'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDatePickerField() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Sermon Date *',
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
