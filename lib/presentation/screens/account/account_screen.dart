import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_credentials.dart';
import '../../../core/themes/app_sizes.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/auth/auth_notifier.dart';
import '../../providers/language/language_notifier.dart';
import '../../providers/main/main_notifier.dart';
import '../../providers/theme/theme_notifier.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = AppSizes.isTablet(context) || AppSizes.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: Center(
        child: Container(
          constraints: isWide ? const BoxConstraints(maxWidth: 600) : null,
          child: const SingleChildScrollView(
            padding: EdgeInsets.all(AppSizes.padding),
            child: Column(
              children: [
                _UserInfo(),
                _ProfileButton(),
                _EmployeeManagementButton(),
                _StoreSettingsButton(),
                _RevenueButton(),
                _CustomerButton(),
                _ThemeButton(),
                _LanguageButton(),
                _PrinterSettingsButton(),
                _PaymentSettingsButton(),
                _ProductDataButton(),
                _AppUpdateButton(),
                _SupabaseConfigButton(),
                _AboutButton(),
                _LogoutButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserInfo extends ConsumerWidget {
  const _UserInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(mainNotifierProvider.select((p) => p.user));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
      child: Column(
        children: [
          AppImage(
            image: user?.imageUrl ?? '',
            width: 120,
            height: 120,
            borderRadius: BorderRadius.circular(100),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            user?.name ?? AppLocalizations.of(context)!.settings_noName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.padding / 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ProfileButton extends StatelessWidget {
  const _ProfileButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_profile,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/profile');
        },
      ),
    );
  }
}

class _StoreSettingsButton extends ConsumerWidget {
  const _StoreSettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.store_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.storeSettings_title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/store-settings');
        },
      ),
    );
  }
}

class _RevenueButton extends ConsumerWidget {
  const _RevenueButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.revenue_title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/revenue');
        },
      ),
    );
  }
}

class _CustomerButton extends StatelessWidget {
  const _CustomerButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  'Pelanggan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/customers');
        },
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.format_paint_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_theme,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          AppDialog.show(
            title: AppLocalizations.of(context)!.settings_theme,
            leftButtonText: AppLocalizations.of(context)!.settings_close,
            child: const _ThemeDialogBody(),
          );
        },
      ),
    );
  }
}

class _LanguageButton extends ConsumerWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageNotifierProvider.select((s) => s.locale));
    final isEnglish = currentLocale.languageCode == 'en';

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.language,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_language,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              isEnglish ? 'English' : 'Indonesia',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () {
          AppDialog.show(
            title: AppLocalizations.of(context)!.settings_language,
            leftButtonText: AppLocalizations.of(context)!.settings_close,
            child: _LanguageDialogBody(
              currentLang: currentLocale.languageCode,
            ),
          );
        },
      ),
    );
  }
}

class _LanguageDialogBody extends ConsumerWidget {
  final String currentLang;

  const _LanguageDialogBody({required this.currentLang});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('Indonesia'),
          leading: Radio<String>(
            value: 'id',
            groupValue: currentLang,
            onChanged: (val) {
              ref.read(languageNotifierProvider.notifier).setLanguage(val!);
              context.pop();
            },
          ),
        ),
        ListTile(
          title: const Text('English'),
          leading: Radio<String>(
            value: 'en',
            groupValue: currentLang,
            onChanged: (val) {
              ref.read(languageNotifierProvider.notifier).setLanguage(val!);
              context.pop();
            },
          ),
        ),
      ],
    );
  }
}

class _PrinterSettingsButton extends StatelessWidget {
  const _PrinterSettingsButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.print_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_printerSettings,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/printer-settings');
        },
      ),
    );
  }
}

class _PaymentSettingsButton extends ConsumerWidget {
  const _PaymentSettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payment_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  'Payment Gateway',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/payment-settings');
        },
      ),
    );
  }
}

class _ProductDataButton extends ConsumerWidget {
  const _ProductDataButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.backup_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.dataProduct_title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/product-data');
        },
      ),
    );
  }
}

class _AppUpdateButton extends ConsumerWidget {
  const _AppUpdateButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.system_update_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_appUpdate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/app-update');
        },
      ),
    );
  }
}

class _AboutButton extends StatelessWidget {
  const _AboutButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  AppLocalizations.of(context)!.settings_about,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/about');
        },
      ),
    );
  }
}

class _EmployeeManagementButton extends ConsumerWidget {
  const _EmployeeManagementButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people_alt_outlined,
                  size: 18,
                ),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  'Kelola Karyawan',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
            ),
          ],
        ),
        onTap: () {
          context.go('/account/employees');
        },
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding, bottom: AppSizes.padding * 2),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.errorContainer,
        textColor: Theme.of(context).colorScheme.error,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: AppSizes.padding / 2),
            Text(
              'Logout',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        onTap: () {
          AppDialog.show(
            title: 'Logout',
            text: 'Yakin ingin logout?',
            leftButtonText: 'Batal',
            rightButtonText: 'Logout',
            rightButtonColor: Theme.of(context).colorScheme.errorContainer,
            rightButtonTextColor: Theme.of(context).colorScheme.error,
            onTapRightButton: (ctx) {
              ctx.pop();
              ref.read(authNotifierProvider.notifier).signOut();
            },
          );
        },
      ),
    );
  }
}

class _ThemeDialogBody extends ConsumerWidget {
  const _ThemeDialogBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);

    return Row(
      children: [
        Switch(
          value: !themeState.isLight,
          onChanged: (val) {
            ref.read(themeNotifierProvider.notifier).changeBrightness(!val);
          },
        ),
        const SizedBox(width: AppSizes.padding),
        Text(
          AppLocalizations.of(context)!.settings_darkMode,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SupabaseConfigButton extends ConsumerWidget {
  const _SupabaseConfigButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConfigured = SupabaseConfig.isConfigured;
    final isAdmin = ref.watch(authNotifierProvider.select((s) => s.user?.role?.value == 'admin'));

    if (!isAdmin) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.padding),
      child: AppButton(
        buttonColor: Theme.of(context).colorScheme.surface,
        borderColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud, size: 18),
                const SizedBox(width: AppSizes.padding / 1.5),
                Text(
                  'Supabase Sync',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Text(
              isConfigured ? 'Aktif' : 'Belum diatur',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isConfigured ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () async {
          final current = await SupabaseCredentials.load();
          final dialogKey = GlobalKey<_SupabaseConfigDialogState>();

          if (!context.mounted) return;

          AppDialog.show(
            title: 'Supabase Sync',
            child: _SupabaseConfigDialog(
              key: dialogKey,
              initialUrl: current?.url ?? '',
              initialAnonKey: current?.anonKey ?? '',
            ),
            rightButtonText: 'Simpan',
            leftButtonText: 'Batal',
            onTapLeftButton: (context) => context.pop(),
            onTapRightButton: (context) async {
              final state = dialogKey.currentState;
              if (state == null) return;

              final url = state.url.trim();
              final anonKey = state.anonKey.trim();

              if (url.isEmpty || anonKey.isEmpty) {
                AppSnackBar.showError('URL dan Anon Key wajib diisi');
                return;
              }

              await SupabaseCredentials.save(url, anonKey);
              if (context.mounted) context.pop();
              AppSnackBar.show('Tersimpan. Restart app untuk mengaktifkan sync');
            },
          );
        },
      ),
    );
  }
}

class _SupabaseConfigDialog extends StatefulWidget {
  final String initialUrl;
  final String initialAnonKey;

  const _SupabaseConfigDialog({super.key, required this.initialUrl, required this.initialAnonKey});

  @override
  State<_SupabaseConfigDialog> createState() => _SupabaseConfigDialogState();
}

class _SupabaseConfigDialogState extends State<_SupabaseConfigDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _anonKeyController;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.initialUrl);
    _anonKeyController = TextEditingController(text: widget.initialAnonKey);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  String get url => _urlController.text;
  String get anonKey => _anonKeyController.text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _urlController,
          hintText: 'Supabase URL',
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: AppSizes.padding),
        AppTextField(
          controller: _anonKeyController,
          hintText: 'Anon / Publishable Key',
          maxLines: 3,
        ),
        const SizedBox(height: AppSizes.padding),
        AppButton(
          text: 'Hapus Konfigurasi',
          textColor: Theme.of(context).colorScheme.error,
          buttonColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          onTap: () async {
            await SupabaseCredentials.clear();
            if (context.mounted) context.pop();
            AppSnackBar.show('Konfigurasi dihapus. Restart app');
          },
        ),
      ],
    );
  }
}
