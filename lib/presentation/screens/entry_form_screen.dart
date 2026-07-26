import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/exif_utils.dart';
import '../../domain/entities/entry.dart';
import '../providers/entry_provider.dart';

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

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxDuration: AppConstants.maxVideoDuration,
      );
      if (picked == null) return;

      final exifDate = await ExifUtils.readExifDate(picked.path);
      if (exifDate != null && widget.existingEntry == null) {
        setState(() {
          _entryDate = exifDate;
          _entryTime = TimeOfDay.fromDateTime(exifDate);
        });
      }

      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9,
          CropAspectRatioPreset.custom,
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Kadruj zdjęcie',
            toolbarColor: AppColors.surfaceDark,
            toolbarWidgetColor: AppColors.textPrimary,
            backgroundColor: AppColors.background,
            activeWidgetColor: AppColors.accent,
            statusBarColor: AppColors.background,
            initAspectRatio: CropAspectRatioPreset.original,
          ),
        ],
      );
      if (cropped == null) return;

      final compressed = await _compressImage(cropped.path);
      setState(() {
        _mediaPath = compressed ?? cropped.path;
        _mediaType = 'image';
      });
    } catch (_) {}
  }

  Future<String?> _compressImage(String path) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${_uuid.v4()}.webp';

      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        targetPath,
        quality: AppConstants.imageQuality,
        format: CompressFormat.webp,
      );
      return result?.path;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickVideo() async {
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: AppConstants.maxVideoDuration,
      );
      if (picked == null) return;

      setState(() {
        _mediaPath = picked.path;
        _mediaType = 'video';
      });
    } catch (_) {}
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
      body: SingleChildScrollView(
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
                  onPressed: _isSaving ? null : _saveEntry,
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
                          style: GoogleFonts.getText('Exo2').copyWith(
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
              style: GoogleFonts.getText('JetBrainsMono').copyWith(
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
              style: GoogleFonts.getText('JetBrainsMono').copyWith(
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
              style: GoogleFonts.getText('Exo2').copyWith(
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
            TextButton.icon(
              onPressed: () => setState(() {
                _mediaPath = null;
                _mediaType = null;
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Usuń media'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo_library),
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
                      onPressed: _pickVideo,
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
