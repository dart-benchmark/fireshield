/// Shared step-wizard chrome, factored out of the PWA's repeated
/// `StepBar` + `Field` pattern (RegisterOrg.jsx, AddFacilityScreen.jsx,
/// AssignAudit.jsx all hand-roll the same thing).
library;

import 'package:flutter/material.dart';

import '../theme/fs_tokens.dart';

class FsStepBar extends StatelessWidget {
  final List<String> steps;
  final int current;
  const FsStepBar({super.key, required this.steps, required this.current});

  @override
  Widget build(BuildContext context) => Container(
        color: FsColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: i < current
                            ? FsColors.eyYellow
                            : i == current
                                ? FsColors.gray900
                                : FsColors.gray100,
                        shape: BoxShape.circle,
                      ),
                      child: i < current
                          ? const Icon(Icons.check,
                              size: 12, color: FsColors.gray900)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: i == current
                                    ? Colors.white
                                    : FsColors.subtle,
                              ),
                            ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      steps[i],
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: i == current
                            ? FsColors.gray900
                            : FsColors.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    width: 14,
                    height: 1,
                    color: i < current
                        ? FsColors.eyYellow
                        : FsColors.gray100,
                  ),
                ),
            ],
          ],
        ),
      );
}

/// Labelled form field wrapper — `Field` in the PWA.
class FsField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;
  final String? hint;

  const FsField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FsColors.gray700,
              ),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                      text: ' *', style: TextStyle(color: FsColors.danger)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint!, style: FsText.micro),
          ],
        ],
      );
}

InputDecoration fsInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: FsText.small.copyWith(color: FsColors.subtle),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FsRadius.xl),
        borderSide: const BorderSide(color: FsColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FsRadius.xl),
        borderSide: const BorderSide(color: FsColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(FsRadius.xl),
        borderSide: const BorderSide(color: FsColors.eyYellow, width: 2),
      ),
    );

class FsDropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const FsDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: fsInputDecoration(hint),
        style: const TextStyle(fontSize: 13, color: FsColors.gray900),
        items: options
            .map((o) => DropdownMenuItem(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: onChanged,
      );
}

/// Bottom Back/Next bar shared by every wizard.
class FsWizardBar extends StatelessWidget {
  final bool showBack;
  final bool canNext;
  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const FsWizardBar({
    super.key,
    required this.showBack,
    required this.canNext,
    required this.onNext,
    this.nextLabel = 'Next',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: FsColors.surface,
          border: Border(top: BorderSide(color: FsColors.border)),
        ),
        child: Row(
          children: [
            if (showBack) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: canNext ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FsColors.eyYellow,
                  foregroundColor: FsColors.gray900,
                  disabledBackgroundColor:
                      FsColors.eyYellow.withValues(alpha: 0.4),
                  elevation: 0,
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FsRadius.xl),
                  ),
                ),
                child: Text(nextLabel,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      );
}

/// Bottom-sheet success confirmation shown after a create/save action.
class FsSuccessSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<(String, String)> details;
  final VoidCallback onClose;

  const FsSuccessSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onClose,
    this.details = const [],
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: FsColors.green100,
                  shape: BoxShape.circle,
                ),
                child: const Text('✅', style: TextStyle(fontSize: 28)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: FsColors.gray900,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle,
                  textAlign: TextAlign.center, style: FsText.small),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: FsColors.gray100,
                    borderRadius: BorderRadius.circular(FsRadius.xl2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: details
                        .map((d) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Text(d.$1, style: FsText.tiny),
                                  const Spacer(),
                                  Text(d.$2,
                                      style: FsText.small.copyWith(
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FsColors.gray900,
                    foregroundColor: FsColors.eyYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FsRadius.xl2),
                    ),
                  ),
                  child: const Text('Done',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );
}
