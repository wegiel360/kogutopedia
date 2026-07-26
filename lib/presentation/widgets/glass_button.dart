import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;

  const GlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppColors.accent;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: btnColor,
                ),
              )
            : icon != null
                ? Icon(icon, size: 20)
                : const SizedBox.shrink(),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor.withOpacity(0.15),
          foregroundColor: btnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: btnColor.withOpacity(0.5), width: 1),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
