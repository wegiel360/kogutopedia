import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/exif_utils.dart';
import '../../core/utils/video_compressor.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_provider.dart';
import '../providers/storage_provider.dart';

class EntryFormScreen extends ConsumerStatefulWidget {
  final Entry? existingEntry;

  const EntryFormScreen({super.key, this.existingEntry});

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCharacterController = TextEditingController();
  final _uuid = const Uuid();

  late DateTime _entryDate;
  late TimeOfDay _entryTime;
  String _selectedCharacter = AppConstants.defaultCharacter;
  String? _mediaPath;
  String? _mediaType;
  bool _isCustomCharacter = false;
  bool _isSaving = false;
  bool _isCompressing = false;
  String _compressionStatus = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _titleController.text = entry.title;
      if (entry.hasDescription) {
        _descriptionController.text = entry.description!;
      }
      _selectedCharacter = entry.characterName;
      _entryDate = entry.entryDate;
      _entryTime = TimeOfDay.fromDateTime(entry.entryDate);
      _mediaPath = entry.mediaPath;
      _mediaType = entry.mediaType;
      if (!AppConstants.predefinedCharacters.contains(entry.characterName)) {
        _isCustomCharacter = true;
        _customCharacterController.text = entry.characterName;
      }
    } else {
      _entryDate = DateTime.now();
      _entryTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCharacterController.dispose();
    super.dispose();
  }

  void _showImageSourceChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Dodaj zdjęcie', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              _sourceOption(
                icon: Icons.photo_library,
                label: 'Z galerii',
                onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.gallery); },
              ),
              const SizedBox(height: 8),
              _sourceOption(
                icon: Icons.camera_alt,
                label: 'Zrób zdjęcie',
                onTap: () { Navigator.of(ctx).pop(); _pickImage(ImageSource.camera); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoSourceChooser() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Dodaj film', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              _sourceOption(
                icon: Icons.photo_library,
                label: 'Z galerii',
                onTap: () { Navigator.of(ctx).pop(); _pickVideo(ImageSource.gallery); },
              ),
              const SizedBox(height: 8),
              _sourceOption(
                icon: Icons.videocam,
                label: 'Nagraj film',
                onTap: () { Navigator.of(ctx).pop(); _pickVideo(ImageSource.camera); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.borderGlow),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _showCompressionProgress(String status) {
    setState(() {
      _isCompressing = true;
      _compressionStatus = status;
    });
  }

  void _hideCompressionProgress() {
    setState(() {
      _isCompressing = false;
      _compressionStatus = '';
    });
  }

  Future<bool> _showCompressionChoice(File file) async {
    final sizeMB = await file.length() / (1024 * 1024);
    final sizeStr = sizeMB.toStringAsFixed(1);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1628),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x8000F0FF), width: 0.5),
        ),
        title: const Text('Kompresja multimediów',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rozmiar pliku: $sizeStr MB',
              style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kompresja zmniejszy rozmiar pliku ale może obniżyć jakość.',
              style: TextStyle(color: Color(0x80FFFFFF), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('compress'),
            child: const Text('Kompresuj',
                style: TextStyle(color: Color(0xFF00F0FF))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('skip'),
            child: const Text('Bez kompresji',
                style: TextStyle(color: Color(0xB3FFFFFF))),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Anuluj',
                style: TextStyle(color: Color(0x80FFFFFF))),
          ),
        ],
      ),
    );
    return result == 'compress';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;

      _showCompressionProgress('Wczytywanie daty ze zdjęcia...');

      try {
        final exifDate = await ExifUtils.readExifDate(picked.path);
        if (exifDate != null && widget.existingEntry == null) {
          setState(() {
            _entryDate = exifDate;
            _entryTime = TimeOfDay.fromDateTime(exifDate);
          });
        }
      } catch (_) {}

      _compressionStatus = 'Przycinanie...';
      String? resultPath;
      try {
        final cropped = await ImageCropper().cropImage(
          sourcePath: picked.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Kadruj zdjęcie',
              toolbarColor: AppColors.surfaceDark,
              toolbarWidgetColor: AppColors.textPrimary,
              backgroundColor: AppColors.background,
              initAspectRatio: CropAspectRatioPreset.original,
              aspectRatioPresets: [
                CropAspectRatioPreset.square,
                CropAspectRatioPreset.ratio3x2,
                CropAspectRatioPreset.original,
                CropAspectRatioPreset.ratio4x3,
                CropAspectRatioPreset.ratio16x9,
              ],
            ),
          ],
        );
        resultPath = cropped?.path;
      } catch (_) {}

      _hideCompressionProgress();
      setState(() {
        _mediaPath = resultPath ?? picked.path;
        _mediaType = 'image';
      });
    } catch (_) {
      _hideCompressionProgress();
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: AppConstants.maxVideoDuration,
      );
      if (picked == null) return;

      _hideCompressionProgress();
      final shouldCompress = await _showCompressionChoice(File(picked.path));
      if (!shouldCompress) {
        setState(() {
          _mediaPath = picked.path;
          _mediaType = 'video';
        });
        return;
      }

      _showCompressionProgress('Kompresowanie filmu...');

      final compressed = await VideoCompressor.compress(File(picked.path));

      setState(() {
        _hideCompressionProgress();
        _mediaPath = compressed?.path ?? picked.path;
        _mediaType = 'video';
      });
    } catch (_) {
      _hideCompressionProgress();
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _entryDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _entryTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.accent,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _entryTime = time);
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final characterName = _isCustomCharacter
        ? _customCharacterController.text.trim()
        : _selectedCharacter;

    if (characterName.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    final entryDate = DateTime(
      _entryDate.year,
      _entryDate.month,
      _entryDate.day,
      _entryTime.hour,
      _entryTime.minute,
    );

    final entry = Entry(
      uuid: widget.existingEntry?.uuid ?? _uuid.v4(),
      createdAt: widget.existingEntry?.createdAt ?? DateTime.now(),
      entryDate: entryDate,
      characterName: characterName,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      mediaPath: _mediaPath,
      mediaType: _mediaType,
    );

    if (widget.existingEntry != null) {
      await ref.read(entryRepositoryProvider).updateEntry(entry);
    } else {
      await ref.read(entryNotifierProvider.notifier).addEntry(entry);
    }

    if (_mediaPath != null) {
      final storage = ref.read(storageProvider.notifier);
      final ext = _mediaType == 'video' ? 'mp4' : 'jpg';
      storage.uploadMedia(
        file: File(_mediaPath!),
        path: 'media/${entry.uuid}.$ext',
        onProgress: (_) {},
      );
    }

    setState(() => _isSaving = false);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.existingEntry != null ? 'Edytuj wpis' : 'Nowy wpis',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateTimeSection(),
                  const SizedBox(height: 20),
                  _buildCharacterSection(),
                  const SizedBox(height: 20),
                  _buildTitleField(),
                  const SizedBox(height: 20),
                  _buildDescriptionField(),
                  const SizedBox(height: 20),
                  _buildMediaSection(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isSaving || _isCompressing) ? null : _saveEntry,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : Text(
                              widget.existingEntry != null
                                  ? 'Zapisz zmiany'
                                  : 'Dodaj wpis',
                              style: GoogleFonts.exo2().copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isCompressing) _buildCompressionOverlay(),
        ],
      ),
    );
  }

  Widget _buildCompressionOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 32,
                width: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _compressionStatus,
                style: GoogleFonts.exo2().copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data i czas',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateButton(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton() {
    return InkWell(
      onTap: _selectDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              AppDateUtils.formatDate(_entryDate),
              style: GoogleFonts.jetBrainsMono().copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton() {
    return InkWell(
      onTap: _selectTime,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppColors.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              _entryTime.format(context),
              style: GoogleFonts.jetBrainsMono().copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.edit, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bohater',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...AppConstants.predefinedCharacters.map((name) {
                final isSelected = !_isCustomCharacter && _selectedCharacter == name;
                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCharacter = name;
                      _isCustomCharacter = false;
                    });
                  },
                  selectedColor: AppColors.accent.withOpacity(0.3),
                );
              }),
              ChoiceChip(
                label: Text(_isCustomCharacter
                    ? _customCharacterController.text.isNotEmpty
                        ? _customCharacterController.text
                        : 'Inny'
                    : 'Inny'),
                selected: _isCustomCharacter,
                onSelected: (_) {
                  setState(() => _isCustomCharacter = true);
                },
                selectedColor: AppColors.accent.withOpacity(0.3),
              ),
            ],
          ),
          if (_isCustomCharacter) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customCharacterController,
              decoration: const InputDecoration(
                labelText: 'Imię',
                hintText: 'Wpisz imię kurczaka',
              ),
              style: GoogleFonts.exo2().copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Tytuł wpisu *',
        hintText: 'Co się dzisiaj wydarzyło?',
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tytuł jest wymagany';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(
        labelText: 'Opis (opcjonalny)',
        hintText: 'Opisz szczegóły...',
        alignLabelWithHint: true,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: 4,
    );
  }

  Widget _buildMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media (opcjonalne)',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (_mediaPath != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: _mediaType == 'image'
                    ? DecorationImage(
                        image: FileImage(File(_mediaPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: AppColors.surfaceMedium,
              ),
              child: _mediaType == 'video'
                  ? const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: AppColors.accent,
                        size: 64,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _showImageSourceChooser,
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Zmień media'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _mediaPath = null;
                    _mediaType = null;
                  }),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Usuń'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceChooser,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Zdjęcie'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.borderGlow),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _showVideoSourceChooser,
                      icon: const Icon(Icons.videocam),
                      label: const Text('Film'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        side: const BorderSide(color: AppColors.borderGlow),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
