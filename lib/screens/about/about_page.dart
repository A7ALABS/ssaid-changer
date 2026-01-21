import 'package:flutter/material.dart';

import 'package:update_device_id/theme/app_colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SSAID Changer',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rooted SSAID editor for Android devices.\n\nThe app mirrors the workflow in "patch_device_id.sh" (you can find this file in the git repo mentioned below) for reading and patching "/data/system/users/0/settings_ssaid.xml".\n\nOn Android 12+ it converts ABX to XML with "abx2xml", updates only the selected package row, then writes back with "xml2abx" and restores permissions.\n\nOn Android 11 and below, the file is plain XML and the app edits it directly. This keeps behavior consistent with the script while adding a UI for selecting apps and updating SSAIDs.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'GitHub repo',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const SelectableText(
                      'https://github.com/A7ALABS/ssaid-changer',
                      style: TextStyle(color: AppColors.accent),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'If this app helped you in any way, please give us a star on our github repo.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              Center(
                child: const Text(
                  'Made with <3 by A7A Labs in India',
                  style: TextStyle(color: AppColors.accent, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
