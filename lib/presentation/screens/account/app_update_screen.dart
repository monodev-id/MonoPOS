import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
        actions: [
          IconButton(
            tooltip: l10n.update_check,
            onPressed: state.isBusy ? null : notifier.checkForUpdate,
            icon: state.status == AppUpdateStatus.checking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.checkForUpdate,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusHero(state: state),
                  const SizedBox(height: AppSizes.padding),
                  _VersionCompareCard(state: state),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _StatusBody(state: state, notifier: notifier),
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  _ActionButtons(state: state, notifier: notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBody extends StatelessWidget {
  final AppUpdateState state;
  final AppUpdateNotifier notifier;

  const _StatusBody({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    if (state.status == AppUpdateStatus.downloading || state.status == AppUpdateStatus.installing) {
      return Column(
        key: const ValueKey('progress'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DownloadProgressCard(state: state),
        ],
      );
    }

    if (state.status == AppUpdateStatus.error && state.error != null) {
      return Column(
        key: const ValueKey('error'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ErrorCard(message: state.error!, onRetry: notifier.checkForUpdate),
        ],
      );
    }

    if (state.status == AppUpdateStatus.available && state.info != null) {
      return Column(
        key: ValueKey('changelog-${state.info!.latestVersion}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChangelogCard(info: state.info!),
        ],
      );
    }

    if (state.status == AppUpdateStatus.upToDate) {
      return const Column(
        key: ValueKey('uptodate'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpToDateCard(),
        ],
      );
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

class _StatusHero extends StatelessWidget {
  final AppUpdateState state;

  const _StatusHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final visuals = _heroVisuals(context, state, l10n);

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: visuals.background,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: visuals.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: visuals.iconBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: visuals.icon,
          ),
          const SizedBox(width: AppSizes.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visuals.title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.02 * 16,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  visuals.subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSizes.padding / 2),
                _HeroStatusPill(state: state),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _HeroVisuals _heroVisuals(BuildContext context, AppUpdateState state, AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    final info = state.info;

    final versionLine = info == null || info.currentVersion == '-'
        ? l10n.update_checking
        : info.isUpdateAvailable
        ? 'v${info.currentVersion} → v${info.latestVersion}'
        : 'v${info.currentVersion}';

    switch (state.status) {
      case AppUpdateStatus.available:
        return _HeroVisuals(
          title: l10n.update_available,
          subtitle: versionLine,
          background: scheme.primaryContainer.withValues(alpha: 0.35),
          border: scheme.primary.withValues(alpha: 0.25),
          iconBackground: scheme.primary,
          icon: Icon(Icons.system_update_rounded, color: scheme.onPrimary, size: 32),
        );
      case AppUpdateStatus.upToDate:
        return _HeroVisuals(
          title: l10n.update_upToDate,
          subtitle: versionLine,
          background: Colors.green.withValues(alpha: 0.12),
          border: Colors.green.withValues(alpha: 0.3),
          iconBackground: Colors.green,
          icon: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
        );
      case AppUpdateStatus.checking:
        return _HeroVisuals(
          title: l10n.update_checking,
          subtitle: l10n.update_check,
          background: scheme.surfaceContainer.withValues(alpha: 0.6),
          border: scheme.surfaceContainerHighest,
          iconBackground: scheme.surfaceContainerHighest,
          icon: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: scheme.primary),
          ),
        );
      case AppUpdateStatus.downloading:
        final percent = (state.progress * 100).toStringAsFixed(0);
        return _HeroVisuals(
          title: l10n.update_downloading(percent),
          subtitle: versionLine,
          background: scheme.primaryContainer.withValues(alpha: 0.35),
          border: scheme.primary.withValues(alpha: 0.25),
          iconBackground: scheme.primary,
          icon: Icon(Icons.arrow_downward_rounded, color: scheme.onPrimary, size: 30),
        );
      case AppUpdateStatus.installing:
        return _HeroVisuals(
          title: l10n.update_installing,
          subtitle: versionLine,
          background: scheme.primaryContainer.withValues(alpha: 0.35),
          border: scheme.primary.withValues(alpha: 0.25),
          iconBackground: scheme.primary,
          icon: Icon(Icons.install_mobile_rounded, color: scheme.onPrimary, size: 28),
        );
      case AppUpdateStatus.error:
        return _HeroVisuals(
          title: l10n.update_retry,
          subtitle: state.error ?? l10n.shared_somethingWrong,
          background: scheme.errorContainer.withValues(alpha: 0.35),
          border: scheme.error.withValues(alpha: 0.25),
          iconBackground: scheme.error,
          icon: Icon(Icons.wifi_off_rounded, color: scheme.onError, size: 28),
          singleLineSubtitle: true,
        );
      case AppUpdateStatus.idle:
        return _HeroVisuals(
          title: l10n.update_title,
          subtitle: l10n.update_check,
          background: scheme.surfaceContainer.withValues(alpha: 0.6),
          border: scheme.surfaceContainerHighest,
          iconBackground: scheme.primary,
          icon: Icon(Icons.system_update_rounded, color: scheme.onPrimary, size: 32),
        );
    }
  }
}

class _HeroVisuals {
  final String title;
  final String subtitle;
  final Color background;
  final Color border;
  final Color iconBackground;
  final Widget icon;
  final bool singleLineSubtitle;

  const _HeroVisuals({
    required this.title,
    required this.subtitle,
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.icon,
    this.singleLineSubtitle = false,
  });
}

class _HeroStatusPill extends StatelessWidget {
  final AppUpdateState state;

  const _HeroStatusPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    final (label, foreground, background) = switch (state.status) {
      AppUpdateStatus.available => (
        l10n.update_available,
        scheme.onPrimary,
        scheme.primary,
      ),
      AppUpdateStatus.upToDate => (
        l10n.update_upToDate,
        Colors.white,
        Colors.green,
      ),
      AppUpdateStatus.checking => (
        l10n.update_checking,
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      AppUpdateStatus.downloading => (
        l10n.update_downloading((state.progress * 100).toStringAsFixed(0)),
        scheme.onPrimary,
        scheme.primary,
      ),
      AppUpdateStatus.installing => (
        l10n.update_installing,
        scheme.onPrimary,
        scheme.primary,
      ),
      AppUpdateStatus.error => (
        l10n.shared_somethingWrong,
        scheme.onError,
        scheme.error,
      ),
      AppUpdateStatus.idle => (
        l10n.update_check,
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _VersionCompareCard extends StatelessWidget {
  final AppUpdateState state;

  const _VersionCompareCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final info = state.info;

    final current = info?.currentVersion ?? '–';
    final latest = info?.latestVersion ?? '–';
    final hasUpdate = info?.isUpdateAvailable ?? false;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _VersionCell(
                  label: l10n.update_currentVersion,
                  version: current,
                  muted: true,
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasUpdate ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasUpdate ? Icons.arrow_forward_rounded : Icons.remove_rounded,
                  size: 18,
                  color: hasUpdate ? scheme.onPrimaryContainer : scheme.outline,
                ),
              ),
              Expanded(
                child: _VersionCell(
                  label: l10n.update_latestVersion,
                  version: latest,
                  alignRight: true,
                  highlight: hasUpdate,
                ),
              ),
            ],
          ),
          if (info != null) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Divider(color: scheme.surfaceContainerHighest, height: 1),
            const SizedBox(height: AppSizes.padding / 2),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (info.publishedAt != null)
                  _MetaChip(
                    icon: Icons.calendar_today_outlined,
                    text: _formatDate(context, info.publishedAt),
                  ),
                if (info.assetSize > 0)
                  _MetaChip(
                    icon: Icons.sd_card_outlined,
                    text: _formatBytes(info.assetSize),
                  ),
                if (info.assetName.isNotEmpty)
                  _MetaChip(
                    icon: Icons.android_rounded,
                    text: info.assetName,
                  ),
              ],
            ),
            if (info.publishedAt == null && info.assetSize <= 0 && info.assetName.isEmpty)
              Text(
                l10n.update_check,
                style: textTheme.bodySmall?.copyWith(color: scheme.outline),
              ),
          ],
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';

    final locale = Localizations.localeOf(context).toLanguageTag();

    try {
      return DateFormat('d MMM y', locale).format(date);
    } catch (_) {
      return DateFormat('d MMM y').format(date);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';

    const units = ['B', 'KB', 'MB', 'GB'];
    var size = bytes.toDouble();
    var unit = 0;

    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }

    return '${size.toStringAsFixed(size >= 100 ? 0 : 1)} ${units[unit]}';
  }
}

class _VersionCell extends StatelessWidget {
  final String label;
  final String version;
  final bool alignRight;
  final bool muted;
  final bool highlight;

  const _VersionCell({
    required this.label,
    required this.version,
    this.alignRight = false,
    this.muted = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.outline,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: highlight ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight ? scheme.primary.withValues(alpha: 0.3) : scheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
          child: Text(
            'v$version',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.01 * 16,
              color: highlight ? scheme.primary : scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.outline),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final AppUpdateInfo info;

  const _ChangelogCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.surfaceContainerHighest, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.history_rounded, size: 19, color: scheme.onTertiaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.update_changelogTitle(info.latestVersion),
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (info.publishedAt != null)
                      Text(
                        l10n.update_releaseDate(_formatDate(context, info.publishedAt)),
                        style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.padding / 2),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSizes.radius),
            ),
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              child: info.releaseNotes.isNotEmpty
                  ? MarkdownBody(
                      data: info.releaseNotes,
                      selectable: true,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                        p: textTheme.bodyMedium?.copyWith(height: 1.55),
                        h1: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        h2: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        h3: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        listBullet: textTheme.bodyMedium?.copyWith(color: scheme.primary),
                        code: textTheme.bodySmall?.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        ),
                      ),
                      onTapLink: (text, href, title) {
                        if (href != null) ExternalLauncher.openUrl(href);
                      },
                    )
                  : Text(
                      l10n.update_noChangelog,
                      style: textTheme.bodySmall?.copyWith(color: scheme.outline),
                    ),
            ),
          ),
          if (info.apkUrl.isEmpty) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppSizes.radius),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: scheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.update_noApk,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return '';

    final locale = Localizations.localeOf(context).toLanguageTag();

    try {
      return DateFormat('d MMM y', locale).format(date);
    } catch (_) {
      return DateFormat('d MMM y').format(date);
    }
  }
}

class _UpToDateCard extends StatelessWidget {
  const _UpToDateCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Colors.green, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.update_upToDate,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scheme.error,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.error_outline_rounded, color: scheme.onError, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(l10n.update_retry),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DownloadProgressCard extends StatelessWidget {
  final AppUpdateState state;

  const _DownloadProgressCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final percent = (state.progress * 100).toStringAsFixed(0);
    final isInstalling = state.status == AppUpdateStatus.installing;

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius + 8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isInstalling ? l10n.update_installing : l10n.update_downloading(percent),
                  style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$percent%',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: isInstalling ? null : state.progress,
              minHeight: 10,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isInstalling ? l10n.update_installing : l10n.update_downloadInstall,
            style: textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final info = state.info;
    final canInstall = state.status == AppUpdateStatus.available && (info?.apkUrl.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canInstall)
          AppButton(
            text: l10n.update_downloadInstall,
            enabled: !state.isBusy,
            onTap: notifier.downloadAndInstall,
          ),
        if (canInstall) const SizedBox(height: AppSizes.padding / 2),
        AppButton(
          text: state.status == AppUpdateStatus.checking ? l10n.update_checking : l10n.update_check,
          enabled: !state.isBusy,
          buttonColor: scheme.surface,
          borderColor: scheme.surfaceContainerHighest,
          textColor: scheme.onSurface,
          onTap: notifier.checkForUpdate,
          child: state.status == AppUpdateStatus.checking
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        if (!canInstall && state.status == AppUpdateStatus.error && state.error != null) ...[
          const SizedBox(height: AppSizes.padding / 2),
          Text(
            l10n.update_androidOnly,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.outline),
          ),
        ],
      ],
    );
  }
}
