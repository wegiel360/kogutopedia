import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/exif_utils.dart';
import '../../core/utils/video_compressor.dart';
import '../../domain/entities/entry.dart';
import '../providers/achievement_provider.dart';
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
  List<String> _mediaPaths = [];
  List<String> _mediaTypes = [];
  bool _isCustomCharacter = false;
  bool _isSaving = false;
  bool _isCompressing = false;
  String _compressionStatus = '';
  bool _isUploading = false;
  String _uploadStatus = '';
  double _uploadProgressValue = 0;
  int _uploadCurrentFile = 0;
  int _uploadTotalFiles = 0;

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
      _mediaPaths = List.from(entry.mediaPaths);
      _mediaTypes = List.from(entry.mediaTypes);
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

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Błąd: $e'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMediaSourceChooser() {
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
              Text('Dodaj multimedia', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
              const SizedBox(height: 20),
              _sourceOption(
                icon: Icons.photo_library,
                label: 'Z galerii',
                onTap: () { Navigator.of(ctx).pop(); _pickMultipleMedia(); },
              ),
              const SizedBox(height: 8),
              _sourceOption(
                icon: Icons.camera_alt,
                label: 'Zrób zdjęcie',
                onTap: () { Navigator.of(ctx).pop(); _pickSingleImage(); },
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

  Future<File> _compressSingleImage(File file) async {
    try {
      final mediaPath = ref.read(databaseProvider).getMediaPath();
      final outPath = '$mediaPath/img_${DateTime.now().millisecondsSinceEpoch}.jpeg';
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        final compressed = img.encodeJpg(decoded, quality: 80);
        await File(outPath).writeAsBytes(compressed);
        return File(outPath);
      }
    } catch (e) {
      debugPrint('Compression error, using original: $e');
    }
    return file;
  }

  Future<void> _pickMultipleMedia() async {
    try {
      final picked = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      final paths = <String>[];
      final types = <String>[];

      if (picked.isNotEmpty) {
        _showCompressionProgress('Przetwarzanie ${picked.length} zdjęć...');
        for (int i = 0; i < picked.length; i++) {
          _compressionStatus = 'Przetwarzanie ${i + 1} / ${picked.length}...';
          final original = File(picked[i].path);
          final compressed = await _compressSingleImage(original);
          paths.add(compressed.path);
          types.add('image');
          if (compressed.path != original.path) {
            unawaited(original.delete());
          }
        }
        _hideCompressionProgress();

        if (widget.existingEntry == null) {
          try {
            final exifDate = await ExifUtils.readExifDate(picked.first.path);
            if (exifDate != null) {
              setState(() {
                _entryDate = exifDate;
                _entryTime = TimeOfDay.fromDateTime(exifDate);
              });
            }
          } catch (e) {
            debugPrint('EXIF read error (multi pick): $e');
          }
        }
      }

      final addVideo = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
          ),
        title: const Text('Dodaj film?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Czy chcesz dodać również film z galerii?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Nie',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Tak',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      );

      if (addVideo == true) {
        final video = await _picker.pickVideo(source: ImageSource.gallery);
        if (video != null) {
          final shouldCompress = await _showCompressionChoice(File(video.path));
          if (shouldCompress) {
            _showCompressionProgress('Kompresowanie filmu...');
            final compressed = await VideoCompressor.compress(
              File(video.path),
              onProgress: (p) {
                setState(() => _compressionStatus = 'Kompresja filmu: $p%');
              },
            );
            _hideCompressionProgress();
            if (compressed != null) {
              final newSizeMB = (await compressed.length()) / (1024 * 1024);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Film: ${newSizeMB.toStringAsFixed(1)} MB'),
                    backgroundColor: AppColors.accent.withOpacity(0.8),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              paths.add(compressed.path);
            } else {
              paths.add(video.path);
            }
          } else {
            paths.add(video.path);
          }
          types.add('video');
        }
      }

      if (paths.isNotEmpty) {
        setState(() {
          _mediaPaths.addAll(paths);
          _mediaTypes.addAll(types);
        });
      }
    } catch (e) {
      _hideCompressionProgress();
      _showError(e);
    }
  }

  Future<void> _pickSingleImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;

      _showCompressionProgress('Przetwarzanie zdjęcia...');

      try {
        final exifDate = await ExifUtils.readExifDate(picked.path);
        if (exifDate != null && widget.existingEntry == null) {
          setState(() {
            _entryDate = exifDate;
            _entryTime = TimeOfDay.fromDateTime(exifDate);
          });
        }
      } catch (e) {
        debugPrint('EXIF read error (single pick): $e');
      }

      final original = File(picked.path);
      final file = await _compressSingleImage(original);

      _hideCompressionProgress();
      if (file.path != original.path) {
        unawaited(original.delete());
      }
      setState(() {
        _mediaPaths.add(file.path);
        _mediaTypes.add('image');
      });
    } catch (e) {
      _hideCompressionProgress();
      _showError(e);
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
          _mediaPaths.add(picked.path);
          _mediaTypes.add('video');
        });
        return;
      }

      _showCompressionProgress('Kompresowanie filmu...');

      final compressed = await VideoCompressor.compress(File(picked.path));

      _hideCompressionProgress();
      if (compressed != null) {
        final newSizeMB = (await compressed.length()) / (1024 * 1024);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Skompresowano: ${newSizeMB.toStringAsFixed(1)} MB'),
              backgroundColor: AppColors.accent.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
      setState(() {
        _mediaPaths.add(compressed?.path ?? picked.path);
        _mediaTypes.add('video');
      });
    } catch (e) {
      _hideCompressionProgress();
      _showError(e);
    }
  }

  Future<bool> _showCompressionChoice(File file) async {
    final sizeMB = await file.length() / (1024 * 1024);
    final sizeStr = sizeMB.toStringAsFixed(1);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderGlow, width: 0.5),
        ),
        title: const Text('Kompresja multimediów',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rozmiar pliku: $sizeStr MB',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kompresja zmniejszy rozmiar pliku ale może obniżyć jakość.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('compress'),
            child: const Text('Kompresuj',
                style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('skip'),
            child: const Text('Bez kompresji',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Anuluj',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
    return result == 'compress';
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

    try {
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
        mediaPaths: _mediaPaths,
        mediaTypes: _mediaTypes,
      );

      if (widget.existingEntry != null) {
        await ref.read(entryRepositoryProvider).updateEntry(entry);
      } else {
        await ref.read(entryNotifierProvider.notifier).addEntry(entry);
        unawaited(ref.read(achievementNotifierProvider.notifier).checkAndUnlockAchievements());
        unawaited(ref.read(achievementNotifierProvider.notifier).completeDailyChallenge());
      }

      setState(() {
        _isSaving = false;
        _isUploading = true;
        _uploadTotalFiles = _mediaPaths.length;
        _uploadCurrentFile = 0;
        _uploadProgressValue = 0;
      });

      final existingPaths = widget.existingEntry?.mediaPaths ?? [];
      final newUploadPaths = <int>[];
      for (int i = 0; i < _mediaPaths.length; i++) {
        if (await File(_mediaPaths[i]).exists() && !existingPaths.contains(_mediaPaths[i])) {
          newUploadPaths.add(i);
        }
      }

      if (newUploadPaths.isNotEmpty) {
        setState(() {
          _uploadTotalFiles = newUploadPaths.length;
          _uploadCurrentFile = 0;
          _uploadProgressValue = 0;
        });

        for (int idx = 0; idx < newUploadPaths.length; idx++) {
          final i = newUploadPaths[idx];
          try {
            final storage = ref.read(storageProvider.notifier);
            final ext = _mediaTypes[i] == 'video' ? 'mp4' : 'jpg';
            setState(() {
              _uploadCurrentFile = idx + 1;
              _uploadStatus = 'Wysyłanie ${idx + 1} / ${newUploadPaths.length}...';
            });
            await storage.uploadMedia(
              file: File(_mediaPaths[i]),
              path: 'media/${entry.uuid}_$i.$ext',
              onProgress: (progress) {
                setState(() {
                  _uploadProgressValue =
                      (idx + progress.fraction) / newUploadPaths.length;
                });
              },
            );
          } catch (e) {
            _showError('Błąd wysyłania pliku ${i + 1}: $e');
          }
        }
      }

      setState(() => _isUploading = false);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Nie udało się zapisać wpisu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isBusy = _isSaving || _isCompressing || _isUploading;
    return PopScope(
      canPop: !isBusy,
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
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
                      onPressed: (_isSaving || _isCompressing || _isUploading) ? null : _saveEntry,
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
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
      ),
    );
  }

  Widget _buildUploadOverlay() {
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
                _uploadStatus,
                style: GoogleFonts.exo2().copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _uploadProgressValue,
                  backgroundColor: AppColors.surfaceMedium,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_uploadCurrentFile / $_uploadTotalFiles plików',
                style: GoogleFonts.jetBrainsMono().copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Media (${_mediaPaths.length})',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 16),
              ),
              if (_mediaPaths.isNotEmpty)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showMediaSourceChooser(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Dodaj'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_mediaPaths.isEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _showMediaSourceChooser,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Dodaj multimedia'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.borderGlow),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _mediaPaths.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _mediaPaths.length) {
                    return SizedBox(
                      width: 100,
                      child: OutlinedButton(
                        onPressed: _showMediaSourceChooser,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.borderGlow),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 32),
                      ),
                    );
                  }
                  return _buildMediaThumbnail(index);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(int index) {
    return Stack(
      children: [
        Container(
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: _mediaTypes[index] == 'image'
                ? DecorationImage(
                    image: FileImage(File(_mediaPaths[index])),
                    fit: BoxFit.cover,
                  )
                : null,
            color: AppColors.surfaceMedium,
          ),
          child: _mediaTypes[index] == 'video'
              ? const Center(
                  child: Icon(Icons.play_circle_outline, color: AppColors.accent, size: 32),
                )
              : null,
        ),
        Positioned(
          top: 4, right: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _mediaPaths.removeAt(index);
                _mediaTypes.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: AppColors.textPrimary, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}
