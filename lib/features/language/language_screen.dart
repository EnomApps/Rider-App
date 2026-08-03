import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_language.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/gradient_button.dart';
import '../../generated/l10n/app_localizations.dart';
import 'widgets/language_tile.dart';

/// Language picker.
///
/// Shown once after the splash on a fresh install ([isInitialSetup] true), and
/// reachable again from the home screen ([isInitialSetup] false).
///
/// Layout note: the headline, the supporting copy and the search field all
/// scroll with the grid rather than sitting in a fixed column above it. Some
/// translations of the subtitle run four times the length of the English one,
/// and on a 320dp screen at a large system font size a fixed header would
/// squeeze the list to zero height and overflow. Only the Continue bar is
/// pinned, and it is built from single-line, shrink-to-fit text.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.isInitialSetup = true});

  final bool isInitialSetup;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _search = TextEditingController();

  late AppLanguage _selected;
  late final AppLanguage _entryLanguage;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final LocaleController controller = context.read<LocaleController>();
    // On a fresh install this is English — the app default.
    _entryLanguage = controller.language;
    _selected = controller.language;
    _search.addListener(() {
      if (_query == _search.text) return;
      setState(() => _query = _search.text);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppLanguage> get _priority =>
      AppLanguages.all.where((AppLanguage l) => l.isPriority).toList();

  List<AppLanguage> get _rest =>
      AppLanguages.all.where((AppLanguage l) => !l.isPriority).toList();

  List<AppLanguage> get _searchResults =>
      AppLanguages.all.where((AppLanguage l) => l.matches(_query)).toList();

  bool get _isSearching => _query.trim().isNotEmpty;

  void _select(AppLanguage language) {
    setState(() => _selected = language);
    // Re-render the whole screen in the tapped language straight away; the
    // choice is only persisted once Continue is pressed.
    context.read<LocaleController>().preview(language);
  }

  Future<void> _confirm() async {
    final NavigatorState navigator = Navigator.of(context);
    final LocaleController controller = context.read<LocaleController>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    await controller.confirm(_selected);
    if (!mounted) return;

    if (widget.isInitialSetup) {
      // First run continues into the auth flow rather than the dashboard.
      navigator.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<void> route) => false,
      );
    } else {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.languageUpdated)));
    }
  }

  /// Discards an un-confirmed preview when the user backs out.
  void _handlePopped(bool didPop, Object? result) {
    if (!didPop) return;
    if (_selected != _entryLanguage) {
      context.read<LocaleController>().restorePersisted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Grid cells are fixed-height, so they have to grow with the user's
    // font-size setting or the two stacked labels would collide.
    final double scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final double tileHeight = 34 + 48 * scale;

    return PopScope<Object?>(
      canPop: !widget.isInitialSetup,
      onPopInvokedWithResult: _handlePopped,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              Expanded(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: _Header(
                        showBack: !widget.isInitialSetup,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SearchField(
                        controller: _search,
                        isSearching: _isSearching,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ..._buildResultSlivers(l10n, tileHeight),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  ],
                ),
              ),
              _BottomBar(selected: _selected, onContinue: _confirm),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildResultSlivers(AppLocalizations l10n, double tileHeight) {
    if (_isSearching) {
      final List<AppLanguage> results = _searchResults;
      if (results.isEmpty) {
        return <Widget>[
          SliverToBoxAdapter(child: _EmptyState(message: l10n.noLanguageFound)),
        ];
      }
      return <Widget>[
        _LanguageGrid(
          languages: results,
          selected: _selected,
          tileHeight: tileHeight,
          onSelect: _select,
          l10n: l10n,
        ),
      ];
    }

    return <Widget>[
      _LanguageGrid(
        languages: _priority,
        selected: _selected,
        tileHeight: tileHeight,
        onSelect: _select,
        l10n: l10n,
      ),
      SliverToBoxAdapter(
        child: _SectionLabel(
          l10n.languagesAvailable(AppLanguages.all.length),
        ),
      ),
      _LanguageGrid(
        languages: _rest,
        selected: _selected,
        tileHeight: tileHeight,
        onSelect: _select,
        l10n: l10n,
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (showBack) ...<Widget>[
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                ),
                const SizedBox(width: 6),
              ] else ...<Widget>[
                const BrandMark(size: 44, radius: 13),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const BrandRule(width: 56, height: 4),
          const SizedBox(height: 14),
          Text(l10n.chooseLanguageTitle, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(l10n.chooseLanguageSubtitle, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.isSearching});

  final TextEditingController controller;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: l10n.searchLanguageHint,
          hintMaxLines: 1,
          prefixIcon: const Icon(Icons.search_rounded, size: 22),
          suffixIcon: isSearching
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: controller.clear,
                  tooltip:
                      MaterialLocalizations.of(context).closeButtonTooltip,
                )
              : null,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({
    required this.languages,
    required this.selected,
    required this.tileHeight,
    required this.onSelect,
    required this.l10n,
  });

  final List<AppLanguage> languages;
  final AppLanguage selected;
  final double tileHeight;
  final ValueChanged<AppLanguage> onSelect;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          // Two columns on a normal phone, three on a tablet, one on a very
          // narrow device — without hard-coding a column count anywhere.
          maxCrossAxisExtent: 260,
          mainAxisExtent: tileHeight,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final AppLanguage language = languages[index];
            return LanguageTile(
              language: language,
              isSelected: language == selected,
              onTap: () => onSelect(language),
              selectedSemanticLabel: l10n.selectedLabel,
              defaultBadgeLabel: l10n.defaultLabel,
            );
          },
          childCount: languages.length,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.translate_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selected, required this.onContinue});

  final AppLanguage selected;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: theme.brightness == Brightness.dark
                        ? AppColors.greenLight
                        : AppColors.greenDeep,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.appLanguageLabel} · ${selected.nativeName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GradientButton(
                label: l10n.continueLabel,
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
