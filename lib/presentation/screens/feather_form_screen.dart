import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/database/kogutopedia_db.dart';
import '../providers/entry_provider.dart';
import '../providers/feather_provider.dart';

class FeatherFormScreen extends ConsumerStatefulWidget {
  const FeatherFormScreen({super.key});

  @override
  ConsumerState<FeatherFormScreen> createState() => _FeatherFormScreenState();
}

class _FeatherFormScreenState extends ConsumerState<FeatherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCharacterController = TextEditingController();

  String _selectedCharacter = AppConstants.defaultCharacter;
  bool _isCustomCharacter = false;
  bool _isUnknownCharacter = false;
  bool _isSaving = false;
  String? _imagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCharacterController.dispose();
    super.dispose();
  }

  Future<void> _pickAndCompressImage() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );
      if (picked == null) return;

      final outPath =
          '${ref.read(databaseProvider).getMediaPath()}/feather_${DateTime.now().millisecondsSinceEpoch}.jpeg';
      await File(picked.path).copy(outPath);
      setState(() => _imagePath = outPath);
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    String? characterName;
    if (_isUnknownCharacter) {
      characterName = null;
    } else if (_isCustomCharacter) {
      characterName = _customCharacterController.text.trim();
      if (characterName.isEmpty) {
        setState(() => _isSaving = false);
        return;
      }
    } else {
      characterName = _selectedCharacter;
    }

    await ref.read(featherNotifierProvider.notifier).addFeather(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          imagePath: _imagePath,
          characterName: characterName,
        );

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
          'Dodaj pióro',
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 20),
              _buildCharacterSection(),
              const SizedBox(height: 20),
              _buildTitleField(),
              const SizedBox(height: 20),
              _buildDescriptionField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
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
                          'Zapisz pióro',
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
    );
  }

  Widget _buildPhotoSection() {
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
            'Zdjęcie pióra',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (_imagePath != null) ...[
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(File(_imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _imagePath = null),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Usuń zdjęcie'),
              style:
                  TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: _pickAndCompressImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Wybierz zdjęcie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.borderGlow),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
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
            'Czyje pióro?',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...AppConstants.predefinedCharacters.map((name) {
                final isSelected = !_isUnknownCharacter &&
                    !_isCustomCharacter &&
                    _selectedCharacter == name;
                return ChoiceChip(
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      _selectedCharacter = name;
                      _isCustomCharacter = false;
                      _isUnknownCharacter = false;
                    });
                  },
                  selectedColor: AppColors.accent.withOpacity(0.3),
                );
              }),
              ChoiceChip(
                label: Text(
                    _isCustomCharacter && _customCharacterController.text.isNotEmpty
                        ? _customCharacterController.text
                        : 'Inny'),
                selected: _isCustomCharacter,
                onSelected: (_) {
                  setState(() {
                    _isCustomCharacter = true;
                    _isUnknownCharacter = false;
                  });
                },
                selectedColor: AppColors.accent.withOpacity(0.3),
              ),
              ChoiceChip(
                label: const Text('Nie wiadomo'),
                selected: _isUnknownCharacter,
                onSelected: (_) {
                  setState(() {
                    _isUnknownCharacter = true;
                    _isCustomCharacter = false;
                  });
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
        labelText: 'Tytuł *',
        hintText: 'Nazwa lub opis pióra',
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
        hintText: 'Kolor, wzór, rozmiar...',
        alignLabelWithHint: true,
      ),
      style: Theme.of(context).textTheme.bodyLarge,
      maxLines: 4,
    );
  }
}
