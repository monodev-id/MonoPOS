import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_sizes.dart';
import '../../../core/utilities/external_launcher.dart';
import '../../../domain/entities/app_update_entity.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/account/app_update_notifier.dart';
import '../../providers/account/app_update_state.dart';
import '../../widgets/app_button.dart';

class AppUpdateScreen extends ConsumerStatefulWidget {
  const AppUpdateScreen({super.key});

  @override
  ConsumerState<AppUpdateScreen> createState() => _AppUpdateScreenState();
}

class _AppUpdateScreenState extends ConsumerState<AppUpdateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appUpdateNotifierProvider.notifier).checkForUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appUpdateNotifierProvider);
    final notifier = ref.read(appUpdateNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.update_title),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VersionCard(state: state),
            if (state.status == AppUpdateStatus.available && state.info != null) ...[
              const SizedBox(height: AppSizes.padding),
              _ChangelogCard(info: state.info!),
            ],
            if (state.status == AppUpdateStatus.error && state.error != null) ...[
              const SizedBox(height: AppSizes.padding),
              _ErrorBox(message: state.error!),
            ],
            if (state.status == AppUpdateStatus.downloading) ...[
              const SizedBox(height: AppSizes.padding),
              _DownloadProgress(progress: state.progress),
            ],
            const SizedBox(height: AppSizes.padding * 1.5),
            _ActionButtons(state: state, notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class _VersionCard extends StatelessWidget {
  final AppUpdateState state;

  const _VersionCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = state.info;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VersionRow(
            label: l10n.update_currentVersion,
            version: info?.currentVersion ?? '-',
          ),
          const SizedBox(height: AppSizes.padding / 2),
          _VersionRow(
            label: l10n.update_latestVersion,
            version: info?.latestVersion ?? '-',
          ),
          const SizedBox(height: AppSizes.padding / 2),
          _StatusBadge(state: state),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String version;

  const _VersionRow({required this.label, required this.version});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          version,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppUpdateState state;

  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final (text, color) = switch (state.status) {
      AppUpdateStatus.available => (l10n.update_available, Theme.of(context).colorScheme.primary),
      AppUpdateStatus.upToDate => (l10n.update_upToDate, Colors.green),
      AppUpdateStatus.checking => (l10n.update_checking, Theme.of(context).colorScheme.outline),
      AppUpdateStatus.downloading => (
        l10n.update_downloading((state.progress * 100).toStringAsFixed(0)),
        Theme.of(context).colorScheme.primary,
      ),
      AppUpdateStatus.installing => (l10n.update_installing, Theme.of(context).colorScheme.primary),
      AppUpdateStatus.error => (state.error ?? l10n.shared_somethingWrong, Theme.of(context).colorScheme.error),
      AppUpdateStatus.idle => ('', Theme.of(context).colorScheme.outline),
    };

    if (text.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Icon(Icons.info_outline, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final AppUpdateInfo info;

  const _ChangelogCard({required this.info});

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final day = date.day.toString().padLeft(2, '0');
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    return '$day ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.update_changelogTitle(info.latestVersion),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (info.publishedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              l10n.update_releaseDate(_formatDate(info.publishedAt)),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
          const SizedBox(height: AppSizes.padding / 2),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              child: info.releaseNotes.isNotEmpty
                  ? MarkdownBody(
                      data: info.releaseNotes,
                      selectable: true,
                      shrinkWrap: true,
                      onTapLink: (text, href, title) {
                        if (href != null) ExternalLauncher.openUrl(href);
                      },
                    )
                  : Text(
                      l10n.update_noChangelog,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
            ),
          ),
          if (info.apkUrl.isEmpty) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Row(
              children: [
                Icon(Icons.warning_amber_outlined, size: 16, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.update_noApk,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
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

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 20),
          const SizedBox(width: AppSizes.padding / 2),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  final double progress;

  const _DownloadProgress({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 6),
        Text(
          '${(progress * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final AppUpdateState state;
  final AppUpdateNotifier notifier;

  const _ActionButtons({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final info = state.info;
    final canInstall = state.status == AppUpdateStatus.available && (info?.apkUrl.isNotEmpty ?? false);

    return Column(
      children: [
        if (canInstall)
          AppButton(
            text: l10n.update_downloadInstall,
            enabled: !state.isBusy,
            onTap: notifier.downloadAndInstall,
          ),
        if (canInstall) const SizedBox(height: AppSizes.padding),
        AppButton(
          text: state.status == AppUpdateStatus.checking ? l10n.update_checking : l10n.update_check,
          enabled: !state.isBusy,
          buttonColor: Theme.of(context).colorScheme.surface,
          borderColor: Theme.of(context).colorScheme.surfaceContainer,
          textColor: Theme.of(context).colorScheme.onSurface,
          onTap: notifier.checkForUpdate,
          child: state.status == AppUpdateStatus.checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ],
    );
  }
}
